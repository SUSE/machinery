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

# The responsibility of the SystemDescription class is to represent a system
# description. This is our main data model.
#
# The content of the system description is stored in a directory, which contains
# a manifest and sub directories for individual scopes. SystemDescription
# handles all the data which is in the top level of the system description
# directory.
#
# The sub directories storing the data for specific scopes are handled by the
# ScopeFileStore class.
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

    def parse_json(name, store, json)
      JSON.parse(json)
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
      error += " in file '#{store.manifest_path(name)}'" if store.persistent?
      error += ":\n\n#{json_error}"

      raise Machinery::Errors::SystemDescriptionError.new(error)
    end

    def validate_json_hash(json_hash)
      return if !compatible_json?(json_hash)

      SystemDescriptionValidator.new(self).validate_json(json_hash)
    end

    def from_json_hash(name, store, json_hash)
      begin
        description = new(name, store, create_scopes(json_hash))
      rescue NameError
        raise Machinery::Errors::SystemDescriptionIncompatible.new(name)
      end

      json_format_version = json_hash["meta"]["format_version"] if json_hash["meta"]
      description.format_version = json_format_version

      description
    end

    def create_scopes(hash)
      scopes = hash.map do |scope_name, scope_json|
        next if scope_name == "meta"

        scope_class = Machinery::ScopeMixin.class_for(scope_name)
        scope_object = scope_class.from_json(scope_json)

        # Set metadata
        if hash["meta"] && hash["meta"][scope_name]
          scope_object.meta = Machinery::Object.from_json(hash["meta"][scope_name])
        end

        [scope_name, scope_object]
      end.compact

      Hash[scopes]
    end

    # Load the system description with the given name
    #
    # If there are file validation errors the call fails with an exception
    def load!(name, store)
      json = store.load_json(name)
      json_hash = parse_json(name, store, json)
      validate_json_hash(json_hash)

      description = from_json_hash(name, store, json_hash)
      description.validate_compatibility
      description.validate_file_data
      description
    end

    # Load the system description with the given name
    #
    # If there are file validation errors these are put out as warnings but the
    # loading of the system description succeeds.
    def load(name, store)
      json = store.load_json(name)
      json_hash = parse_json(name, store, json)
      validate_json_hash(json_hash)

      description = from_json_hash(name, store, json_hash)
      description.validate_compatibility
      begin
        description.validate_file_data
      rescue Machinery::Errors::SystemDescriptionValidationFailed => e
        Machinery::Ui.warn("Warning: File validation errors:")
        Machinery::Ui.warn(e.to_s)
      end
      description
    end

    def validate_name(name)
      if ! /^[\w\.:-]*$/.match(name)
        raise Machinery::Errors::SystemDescriptionError.new(
          "System description name \"#{name}\" is invalid. " +
          "Only \"a-zA-Z0-9_:.-\" are valid characters."
        )
      end

      if name.start_with?(".")
        raise Machinery::Errors::SystemDescriptionError.new(
          "System description name \"#{name}\" is invalid. " +
          "A dot is not allowed as first character."
        )
      end
    end

    private

    def compatible_json?(json)
      json.is_a?(Hash) &&
        json["meta"].is_a?(Hash) &&
        json["meta"]["format_version"] == CURRENT_FORMAT_VERSION
    end
  end

  def initialize(name, store, hash = {})
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

    attributes.keys.each do |key|
      meta[key] = self[key].meta.as_json if self[key].meta
    end

    hash = as_json
    hash["meta"] = meta unless meta.empty?
    hash
  end

  def to_json
    JSON.pretty_generate(to_hash)
  end

  def save
    SystemDescription.validate_name(name)
    @store.directory_for(name)
    path = @store.manifest_path(name)
    created = !File.exists?(path)
    File.write(path, to_json)
    File.chmod(0600, path) if created
  end

  def scopes
    attributes.keys.map(&:to_s).sort
  end

  def assert_scopes(*scopes)
    missing = scopes.select { |scope| !self[scope] || self[scope].empty? }

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

    file_list.select { |file| !File.exists?(file) }
  end

  def additional_files(scope, file_list)
    file_list.map! { |file| File.join(file_store(scope), file) }
    files = list_file_store_content(scope)

    files - file_list
  end

  def validate_file_data
    SystemDescriptionValidator.new(self).validate_file_data
  end

  def description_path
    @store.description_path(name)
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
