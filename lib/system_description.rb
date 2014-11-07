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
  CURRENT_FORMAT_VERSION = 2
  EXTRACTABLE_SCOPES = [
    "changed_managed_files",
    "config_files",
    "unmanaged_files"
  ]

  attr_accessor :name
  attr_accessor :store
  attr_accessor :format_version

  class << self
    def from_json(name, json, store = nil)
      begin
        json_hash = JSON.parse(json)
      rescue JSON::ParserError => e
        lines = e.message.split("\n")
        error_pos = json.split("\n").length - lines.length + 2
        block_end = lines.index { |l| l =~ / [\}\]],?$/ }

        # remove needless json error information
        lines[0].gsub!(/^\d+: (.*)$/, "\\1")
        json_error = lines[0..block_end].join("\n")

        if error_pos == 1
          json_error = "An opening bracket, a comma or quotation is missing " \
            "in one of the global scope definitions or in the meta section. " \
            "Unlike issues with the elements of the scopes, our JSON parser " \
            "isn't able to locate issues like these."
          error_pos = nil
        end

        error = "The JSON data of the system description '#{name}' " \
          "couldn't be parsed. The following error occured"
        error += " around line #{error_pos}" if error_pos
        error += " in file '#{store.manifest_path(name)}'" if store
        error += ":\n\n#{json_error}"

        raise Machinery::Errors::SystemDescriptionError.new(error)
      end

      if compatible_json?(json_hash)
        SystemDescriptionValidator.new(self).validate_json(json_hash)
      end

      begin
        description = self.new(name, self.create_scopes(json_hash), store)
      rescue NameError
        raise Machinery::Errors::SystemDescriptionIncompatible.new(name)
      end

      json_format_version = json_hash["meta"]["format_version"] if json_hash["meta"]
      description.format_version = json_format_version

      description
    end

    def create_scopes(hash)
      entries = hash.map do |key, value|
        next if key == "meta"

        if key == "os"
          os = Os.for(value["name"])
          value_converted = os.set_attributes(value)
        else
          class_name = "#{key.split("_").map(&:capitalize).join}Scope"
          value_converted = Object.const_get(class_name).from_json(value)
        end

        # Set metadata
        if hash["meta"] && hash["meta"][key]
          value_converted.meta = Machinery::Object.from_json(hash["meta"][key])
        end

        [key, value_converted]
      end.compact

      Hash[entries]
    end

    private

    def compatible_json?(json)
      json.is_a?(Hash) &&
        json["meta"].is_a?(Hash) &&
        json["meta"]["format_version"] == CURRENT_FORMAT_VERSION
    end
  end

  def initialize(name, hash = {}, store = nil)
    @name = name
    @store = store
    @format_version = CURRENT_FORMAT_VERSION

    super(hash)
  end

  def compatible?
    !format_version.nil? &&
      format_version == SystemDescription::CURRENT_FORMAT_VERSION
  end

  def validate_compatibility
    if !compatible?
      raise Machinery::Errors::SystemDescriptionIncompatible.new(self.name)
    end
  end

  def to_hash
    meta = {}
    meta["format_version"] = self.format_version if self.format_version

    attributes.each do |key, value|
      meta[key] = self[key].meta.as_json if self[key].meta
    end

    hash = as_json
    hash["meta"] = meta unless meta.empty?
    hash
  end

  def to_json
    JSON.pretty_generate(to_hash)
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
    self[scope] && self[scope].is_extractable? && self[scope].extracted
  end

  def missing_files(scope, file_list)
    file_list.map! { |file| File.join(file_store(scope), file) }

    file_list.select do |file|
      !File.exists?(file)
    end
  end

  def additional_files(scope, file_list)
    file_list.map! { |file| File.join(file_store(scope), file) }
    files = list_file_store_content(scope)

    files - file_list
  end

  def validate_file_data
    SystemDescriptionValidator.new(self).validate_file_data
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

  def rename_file_store(old_name, new_name)
    @store.rename_file_store(self.name, old_name, new_name)
  end

  def list_file_store_content(store_name)
    @store.list_file_store_content(self.name, store_name)
  end

  def create_file_store_sub_dir(store_name, sub_dir)
    @store.create_file_store_sub_dir(self.name, store_name, sub_dir)
  end
end
