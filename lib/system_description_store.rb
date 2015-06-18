# Copyright (c) 2013-2015 SUSE LLC
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

# The responsibility of the SystemDescriptionStore class is to handle the
# directory where the system description is stored. It provides methods to
# create, delete, and copy descriptions within the top-level directory.
#
# System descriptions are represented by sub directories of this top-level
# directory. They are handled by the SystemDescription class.
class SystemDescriptionStore
  attr_reader :base_path

  def default_path
    Machinery::DEFAULT_CONFIG_DIR
  end

  def persistent?
    true
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

  def list
    Dir["#{@base_path}/*"].
      select { |item| File.exists?(manifest_path(File.basename(item)))}.
      map { |item| File.basename(item) }.sort
  end

  def remove(name)
    unless name.empty?
      SystemDescription.validate_name(name)
      FileUtils.rm_rf(description_path(name))
    else
      raise "The system description has no name specified and thus can't be deleted."
    end
  end

  def copy(from, to)
    SystemDescription.validate_name(from)
    SystemDescription.validate_name(to)

    validate_existence_of_description(from)
    validate_nonexistence_of_description(to)

    FileUtils.cp_r(description_path(from), description_path(to))
  end

  def backup(description_name)
    SystemDescription.validate_name(description_name)
    validate_existence_of_description(description_name)

    backup_name = get_backup_name(description_name)

    FileUtils.cp_r(description_path(description_name), description_path(backup_name))
    backup_name
  end

  def rename(from, to)
    SystemDescription.validate_name(from)
    SystemDescription.validate_name(to)

    validate_existence_of_description(from)
    validate_nonexistence_of_description(to)

    FileUtils.mv(description_path(from), description_path(to))
  end

  def swap(description_name_1, description_name_2)
    validate_existence_of_description(description_name_1)
    validate_existence_of_description(description_name_2)

    tmp_description_name = "#{description_name_1}-#{Time.now.to_i}-#{rand(1000)}"

    FileUtils.mv(description_path(description_name_1), description_path(tmp_description_name))
    FileUtils.mv(description_path(description_name_2), description_path(description_name_1))
    FileUtils.mv(description_path(tmp_description_name), description_path(description_name_2))
  end

  def directory_for(name)
    dir = description_path(name)
    create_dir(dir)
    dir
  end

  private

  def create_dir(dir, mode = 0700)
    unless Dir.exists?(dir)
      FileUtils.mkdir_p(dir, mode: mode)
    end
  end

  def get_backup_name(description_name)
    backup_name = "#{description_name}.backup"
    number = 1

    while list.include?(backup_name)
      backup_name = "#{description_name}.backup.#{number}"
      number += 1
    end

    backup_name
  end

  def validate_existence_of_description(description_name)
    if !list.include?(description_name)
      raise Machinery::Errors::SystemDescriptionNotFound.new(
        "System description '#{description_name}' does not exist."
      )
    end
  end

  def validate_nonexistence_of_description(description_name)
    if list.include?(description_name)
      raise Machinery::Errors::SystemDescriptionError.new(
        "A System description with the name '#{description_name}' does already exist."
      )
    end
  end
end
