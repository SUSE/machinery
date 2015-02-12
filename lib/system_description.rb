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
  CURRENT_FORMAT_VERSION = 3
  EXTRACTABLE_SCOPES = [
    "changed_managed_files",
    "config_files",
    "unmanaged_files"
  ]

  attr_accessor :name
  attr_accessor :store
  attr_accessor :format_version

  class << self
    # Load the system description with the given name
    #
    # If there are file validation errors the call fails with an exception
    def load!(name, store, options = {})
      manifest = Manifest.load(name, store.manifest_path(name))
      manifest.validate!

      description = from_hash(name, store, manifest.to_hash)
      description.validate_file_data!

      if !options[:skip_format_compatibility]
        description.validate_format_compatibility
      end

      description
    end

    # Load the system description with the given name
    #
    # If there are file validation errors these are put out as warnings but the
    # loading of the system description succeeds.
    def load(name, store, options = {})
      manifest = Manifest.load(name, store.manifest_path(name))
      manifest.validate

      description = from_hash(name, store, manifest.to_hash)
      description.validate_file_data

      if !options[:skip_format_compatibility]
        description.validate_format_compatibility
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

    def from_hash(name, store, hash)
      begin
        description = SystemDescription.new(name, store, create_scopes(hash))
      rescue NameError
        raise Machinery::Errors::SystemDescriptionIncompatible.new(name)
      end

      json_format_version = hash["meta"]["format_version"] if hash["meta"]
      description.format_version = json_format_version

      description
    end

    private

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

  def validate_format_compatibility
    if !compatible?
      raise Machinery::Errors::SystemDescriptionIncompatible.new(self.name)
    end
  end

  def validate_analysis_compatibility
    if !os.can_be_analyzed?
      raise Machinery::Errors::AnalysisFailed.new("Analysis of operating " +
        "system '#{os.display_name}' is not supported.")
    end
  end

  def validate_export_compatibility
    if !os.can_be_exported?
      raise Machinery::Errors::ExportFailed.new("Export of operating " +
        "system '#{os.display_name}' is not supported.")
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

  def scope_file_store(store_name)
    ScopeFileStore.new(description_path, store_name)
  end

  def validate_file_data
    errors = SystemDescriptionValidator.new(to_hash, description_path).validate_file_data
    if !errors.empty?
      Machinery::Ui.warn("Warning: File validation errors:")
      Machinery::Ui.warn("Error validating description '#{@name}'\n\n")
      Machinery::Ui.warn(errors)
    end
  end

  def validate_file_data!
    errors = SystemDescriptionValidator.new(to_hash, description_path).validate_file_data
    if !errors.empty?
      e = Machinery::Errors::SystemDescriptionValidationFailed.new(errors)
      e.header = "Error validating description '#{@name}'"
      raise e
    end
  end

  def description_path
    @store.description_path(name)
  end
end
