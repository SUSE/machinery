# Copyright (c) 2013-2014 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

class SystemDescriptionStore
  attr_reader :base_path

  def default_path
    Machinery::DEFAULT_CONFIG_DIR
  end

  def initialize(base_path = default_path)
    @base_path = base_path
    create_dir(@base_path)
  end

  def description_path(name)
    File.join(@base_path, name)
  end

  def manifest_path(name)
    File.join(description_path(name), "manifest.json")
  end

  def html_path(name)
    File.join(description_path(name), "index.html")
  end

  def load_json(name)
    validate_name(name)
    file_name = manifest_path(name)
    unless File.exists?(file_name)
      raise Machinery::Errors::SystemDescriptionNotFound.new(
        "A system description with the name #{name} was not found."
      )
    end
    File.read(file_name)
  end

  def load(name)
    json = load_json(name)
    description = SystemDescription.from_json(name, json, self)
    description.validate_compatibility
    description.validate_file_data
    description
  end

  def save(description)
    validate_name(description.name)
    create_dir(description_path(description.name))
    path = manifest_path(description.name)
    created = !File.exists?(path)
    File.write(path, description.to_json)
    File.chmod(0600,path) if created
  end

  def list
    Dir["#{@base_path}/*"].
      select { |item| File.exists?(manifest_path(File.basename(item)))}.
      map { |item| File.basename(item) }
  end

  def remove(name)
    unless name.empty?
      validate_name(name)
      FileUtils.rm_rf(description_path(name))
    else
      raise "The system description has no name specified and thus can't be deleted."
    end
  end

  def copy(from, to)
    validate_name(from)
    validate_name(to)
    if !list.include?(from)
      raise Machinery::Errors::SystemDescriptionNotFound.new(
        "System description \"#{from}\" does not exist."
      )
    end

    if list.include?(to)
      raise Machinery::Errors::SystemDescriptionError.new(
        "A System description with the name \"#{to}\" does already exist."
      )
    end

    FileUtils.cp_r(description_path(from), description_path(to))
  end

  def initialize_file_store(description_name, store_name)
    dir = File.join(description_path(description_name), store_name)
    create_dir(dir, new_dir_mode(description_name))
  end

  def file_store(description_name, store_name)
    dir = File.join(description_path(description_name), store_name)
    Dir.exists?(dir) ? dir : nil
  end

  def remove_file_store(description_name, store_name)
    FileUtils.rm_rf(File.join(description_path(description_name), store_name))
  end

  def rename_file_store(description_name, store_old, store_new)
    FileUtils.mv(
      File.join(description_path(description_name), store_old),
      File.join(description_path(description_name), store_new)
    )
  end

  def create_file_store_sub_dir(description_name, store_name, sub_dir)
    dir = File.join(description_path(description_name), store_name, sub_dir)
    create_dir(dir, new_dir_mode(description_name))
  end

  def list_file_store_content(description_name, store_name)
    dir = File.join(description_path(description_name), store_name)

    files = Dir.glob(File.join(dir, "**/{*,.*}"))
    # filter parent directories because they should not be listed separately
    files.reject { |f| files.index { |e| e =~ /^#{f}\/.+/ } }
  end

  def new_dir_mode(name)
    mode = 0700
    if Dir.exists?(description_path(name))
      mode = File.stat(description_path(name)).mode & 0777
    end
    mode
  end

  private

  def create_dir(dir, mode = 0700)
    unless Dir.exists?(dir)
      FileUtils.mkdir_p(dir, :mode => mode)
    end
  end

  def validate_name(name)
    if ! /^[\w\.:-]*$/.match(name)
      raise Machinery::Errors::SystemDescriptionError.new(
        "System description name \"#{name}\" is invalid. Only \"a-zA-Z0-9_:.-\" are valid characters."
      )
    end

    if name.start_with?(".")
      raise Machinery::Errors::SystemDescriptionError.new(
        "System description name \"#{name}\" is invalid. A dot is not allowed as first character."
      )
    end

  end
end
