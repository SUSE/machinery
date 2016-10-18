# Copyright (c) 2013-2016 SUSE LLC
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
class Machinery::SystemDescription < Machinery::Object
  CURRENT_FORMAT_VERSION = 10
  EXTRACTABLE_SCOPES = [
    "changed_managed_files",
    "changed_config_files",
    "unmanaged_files"
  ]

  attr_accessor :name
  attr_accessor :store
  attr_accessor :format_version
  attr_accessor :filter_definitions

  class << self
    # Load the system description with the given name
    #
    # If there are file validation errors the call fails with an exception
    def load!(name, store, options = {})
      manifest = Manifest.load(name, store.manifest_path(name))
      manifest.validate!

      description = from_hash(name, store, manifest.to_hash)
      description.validate_file_data!

      unless options[:skip_format_compatibility]
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
      manifest.validate unless options[:skip_validation]

      description = from_hash(name, store, manifest.to_hash)
      description.validate_file_data unless options[:skip_validation]

      description.validate_format_compatibility unless options[:skip_format_compatibility]

      description
    end

    def valid_name?(name)
      !!/^[\w:-][\w\.:-]*$/.match(name)
    end

    def validate_name(name)
      unless valid_name?(name)
        raise Machinery::Errors::SystemDescriptionError.new(
          "System description name '#{name}' is invalid. " \
          "Only 'a-zA-Z0-9_:.-' are valid characters and a dot " \
          "is not allowed at the begginning."
        )
      end
    end

    def from_hash(name, store, hash)
      begin
        json_format_version = hash["meta"]["format_version"] if hash["meta"]
        description = Machinery::SystemDescription.new(name, store, hash)
      rescue NameError, TypeError, RuntimeError
        if json_format_version &&
            json_format_version != Machinery::SystemDescription::CURRENT_FORMAT_VERSION
          raise Machinery::Errors::SystemDescriptionIncompatible.new(name, json_format_version)
        else
          raise Machinery::Errors::SystemDescriptionError.new(
            "#{name}: This description is broken."
          )
        end
      end

      description.format_version = json_format_version

      if hash["meta"] && hash["meta"]["filters"]
        description.filter_definitions = hash["meta"]["filters"]
      end

      description
    end
  end

  def initialize(name, store, hash = {})
    @name = name
    @store = store
    @format_version = CURRENT_FORMAT_VERSION
    @filter_definitions = {}

    super(create_scopes(hash))
  end

  def create_scopes(hash)
    scopes = hash.map do |scope_name, json|
      next if scope_name == "meta"

      if store.persistent?
        scope_file_store = scope_file_store(scope_name)
      end

      if json.is_a?(Hash) || json.is_a?(Array)
        scope_object = Machinery::Scope.for(scope_name, json, scope_file_store)

        # Set metadata
        if hash["meta"] && hash["meta"][scope_name]
          scope_object.meta = Machinery::Object.from_json(hash["meta"][scope_name])
        end
      else
        scope_object = json
      end

      [scope_name, scope_object]
    end.compact

    Hash[scopes]
  end

  def compatible?
    !format_version.nil? &&
      format_version == Machinery::SystemDescription::CURRENT_FORMAT_VERSION
  end

  def validate_format_compatibility
    unless compatible?
      raise Machinery::Errors::SystemDescriptionIncompatible.new(name, format_version)
    end
  end

  def validate_analysis_compatibility
    Machinery::Zypper.isolated(arch: os.architecture) do |zypper|
      major, minor, patch = zypper.version
      if major <= 1 && minor <= 11 && patch < 4
        raise Machinery::Errors::AnalysisFailed.new("Analyzing command requires zypper 1.11.4 " \
          "or grater to be installed.")
      end
    end
  end

  def validate_build_compatibility
    kiwi_template_path = "/usr/share/kiwi/image/#{os.kiwi_boot}"
    unless Dir.exist?(kiwi_template_path)
      raise Machinery::Errors::BuildFailed.new("The execution of the build script failed. " \
        "Building of operating system '#{os.display_name}' can't be accomplished because the " \
        "kiwi template file in `#{kiwi_template_path}` does not exist.")
    end
  end

  def to_hash
    meta = {}
    meta["format_version"] = self.format_version if self.format_version

    attributes.keys.each do |key|
      meta[key] = self[key].meta.as_json if self[key].meta
    end
    @filter_definitions.each do |command, filter|
      meta["filters"] ||= {}
      meta["filters"][command] = filter
    end

    hash = as_json
    hash["meta"] = meta unless meta.empty?
    hash
  end

  def to_json
    JSON.pretty_generate(to_hash)
  end

  def save
    Machinery::SystemDescription.validate_name(name)
    @store.directory_for(name)
    path = @store.manifest_path(name)
    created = !File.exist?(path)
    File.write(path, to_json)
    File.chmod(0600, path) if created
  end

  def filter_definitions(command)
    @filter_definitions[command] || []
  end

  def set_filter_definitions(command, filter)
    unless ["inspect"].include?(command)
      raise Machinery::Errors::MachineryError.new(
        "Storing the filter for command '#{command}' is not supported."
      )
    end

    @filter_definitions[command] = filter
  end

  def scopes
    Inspector.sort_scopes(attributes.keys.map(&:to_s).sort)
  end

  def assert_scopes(*scopes)
    missing = scopes.select { |scope| !self[scope] }.map { |scope|
      Machinery::Ui.internal_scope_list_to_string(scope)
    }

    unless missing.empty?
      raise Machinery::Errors::SystemDescriptionError.new(
        "The system description misses the following" \
          " #{Machinery.pluralize(missing.size, "scope")}: #{missing.join(",")}."
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
    errors = FileValidator.new(to_hash, description_path).validate
    unless errors.empty?
      Machinery::Ui.warn("Warning: File validation errors:")
      Machinery::Ui.warn("Error validating description '#{@name}'\n\n")
      Machinery::Ui.warn(errors.join("\n"))
    end
  end

  def validate_file_data!
    errors = FileValidator.new(to_hash, description_path).validate
    unless errors.empty?
      e = Machinery::Errors::SystemDescriptionValidationFailed.new(errors)
      e.header = "Error validating description '#{@name}'"
      raise e
    end
  end

  def latest_update
    attributes.keys.map { |scope| self[scope].meta.try(:[], "modified") }
      .compact.map { |t| Time.parse(t) }.sort.last
  end

  def host
    all_hosts = attributes.keys.map { |scope| self[scope].meta.try(:[], "hostname") }
    all_hosts.uniq.compact
  end

  def description_path
    @store.description_path(name)
  end

  def runs_service?(name)
    self["services"].any? { |service| service.name == "#{name}.service" }
  end

  def has_file?(name)
    EXTRACTABLE_SCOPES.each do |scope|
      if scope_extracted?(scope)
        return true if self[scope] && self[scope].has_file?(name)
      end
    end
    false
  end

  def read_config(path, key)
    EXTRACTABLE_SCOPES.each do |scope|
      if scope_extracted?(scope)
        file = self[scope].find { |f| f.name == path }
        return parse_variable_assignment(file.content, key) if file
      end
    end
  end

  # Enrich description with the config file diffs
  def load_existing_diffs
    diffs_dir = scope_file_store("analyze/changed_config_files_diffs").path
    return unless changed_config_files && diffs_dir
    changed_config_files.each do |file|
      path = File.join(diffs_dir, file.name + ".diff")
      file.diff = DiffWidget.new(File.read(path)).widget if File.exist?(path)
    end
  end

  private

  def parse_variable_assignment(string, variable)
    /^(?#) *#{variable} *(=|:| ) *(.*)/.match(string).to_a.fetch(2, "").gsub(/\"/, "").strip
  end
end
