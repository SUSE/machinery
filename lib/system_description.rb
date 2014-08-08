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

class SystemDescription < Machinery::Object
  attr_accessor :name
  attr_accessor :store

  def self.add_validator(json_path, &block)
    @@json_validator[json_path] = block
  end

  def initialize(name, hash = {}, store = nil)
    @name = name
    @store = store

    super(hash)
  end

  def self.from_json(name, json, store = nil)
    json_hash = JSON.parse(json)

    if !json_hash.is_a?(Hash)
      raise Machinery::Errors::SystemDescriptionError.new(
        "System descriptions must have a hash as the root element"
      )
    end

    @@json_validator.each do |json_path, block|
      pointer = JsonPointer.new(json_hash, json_path, :symbolize_keys => false)
      block.yield pointer.value if pointer.exists?
    end

    self.new(name, self.create_attrs(json_hash), store)
  end

  def self.create_attrs(hash)
    entries = hash.map do |key, value|
      next if key == "meta"

      class_name = "#{key.split("_").map(&:capitalize).join}Scope"
      value_converted = Object.const_get(class_name).from_json(value)

      # Set metadata
      if hash["meta"] && hash["meta"][key]
        value_converted.meta = Machinery::Object.from_json(hash["meta"][key])
      end

      [key, value_converted]
    end.compact

    Hash[entries]
  end

  def to_json
    hash = as_json
    meta = {}
    attributes.each do |key, value|
      meta[key] = self[key].meta.as_json if self[key].meta
    end
    hash["meta"] = meta if !meta.empty?

    JSON.pretty_generate(hash)
  end

  def scopes
    scopes = attributes.map {
      |key, value| key.to_s
    }.sort
    scopes
  end

  def assert_scopes(*scopes)
    missing = scopes.reject do |e|
      self.send(e) && !self.send(e).empty?
    end

    unless missing.empty?
      raise Machinery::Errors::SystemDescriptionError.new(
        "The system description misses the following section(s): #{missing.join(", ")}."
      )
    end
  end

  def short_os_version
    assert_scopes("os")

    case self.os.name
      when /^SUSE Linux Enterprise Server/
        "sles" + self.os.version[/\d+( SP\d+)*/].gsub(" ", "").downcase
      when /^openSUSE/
        self.os.version[/^\d+.\d+/]
      else
        "unknown"
    end
  end

  def scope_extracted?(scope)
    extracting_scopes = [
      "changed_managed_files",
      "config_files",
      "unmanaged_files"
    ]

    extracting_scopes.include?(scope) && !@store.file_store(name, scope).nil?
  end

  def os_object
    assert_scopes("os")

    [OsSles12, OsSles11, OsOpenSuse13_1].each do |os_class|
      os_object = os_class.new
      if self.os.name == os_object.name
        return os_object
      end
    end

    raise Machinery::Errors::SystemDescriptionError.new(
      "Unrecognized operating system '#{self.os.name}")
  end

  # Filestore handling
  def initialize_file_store(store_name)
    @store.initialize_file_store(self.name, store_name)
  end

  def file_store(store_name)
    @store.file_store(self.name, store_name)
  end

  def remove_file_store(store_name)
    @store.remove_file_store(self.name, store_name)
  end

  def create_file_store_sub_dir(store_name, sub_dir)
    @store.create_file_store_sub_dir(self.name, store_name, sub_dir)
  end

  private

  @@json_validator = Hash.new
end
