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
  CURRENT_FORMAT_VERSION = 1

  attr_accessor :name
  attr_accessor :store
  attr_accessor :format_version

  class << self
    def add_validator(json_path, &block)
      @@json_validator[json_path] = block
    end

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
            "isn't able to localize issues like these."
          error_pos = nil
        end

        error = "The JSON data of the system description '#{name}' " \
          "couldn't be parsed. The following error occured"
        error += " around line #{error_pos}" if error_pos
        error += " in file '#{store.manifest_path(name)}'" if store
        error += ":\n\n#{json_error}"

        raise Machinery::Errors::SystemDescriptionError.new(error)
      end
      validate_json(json_hash) if compatible_json?(json_hash)

      begin
        description = self.new(name, self.create_attrs(json_hash), store)
      rescue NameError
        raise Machinery::Errors::SystemDescriptionError.new(
          "The system description #{name} has an incompatible data format and can" \
          " not be read.\n\n"
        )
      end

      json_format_version = json_hash["meta"]["format_version"] if json_hash["meta"]
      description.format_version = json_format_version

      description
    end

    def create_attrs(hash)
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

    private

    def load_global_schema
      JSON.parse(File.read(File.join(
        Machinery::ROOT,
        "schema",
        "v#{CURRENT_FORMAT_VERSION}",
        "system-description-global.schema.json"
      )))
    end

    def load_scope_schemas
      schema_dir = File.join(
        Machinery::ROOT,
        "plugins",
        "schema",
        "v#{CURRENT_FORMAT_VERSION}"
      )

      Hash[
        Dir["#{schema_dir}/*.schema.json"].map do |file|
          scope = file.match(/system-description-(.*)\.schema\.json$/)[1].tr("-", "_")
          schema = JSON.parse(File.read(file))

          [scope, schema]
        end
      ]
    end

    def compatible_json?(json)
      json.is_a?(Hash) &&
        json["meta"].is_a?(Hash) &&
        json["meta"]["format_version"] == CURRENT_FORMAT_VERSION
    end

    def validate_json(json)
      errors = JSON::Validator.fully_validate(GLOBAL_SCHEMA, json)

      scopes = json.keys
      scopes.delete("meta")

      errors += scopes.flat_map do |scope|
        schema = SCOPE_SCHEMAS[scope]

        if schema
          issue = JSON::Validator.fully_validate(schema, json[scope]).map do |error|
            "In scope #{Machinery::Ui.internal_scope_list_to_string(scope)}:" \
              " #{error}"
          end

          # filter duplicates
          issue.map! do |error|
            lines = error.split("\n")
            lines.uniq.join("\n")
          end

          # make json error messages more user-friendly
          if ["config_files", "changed_managed_files"].include?(scope)
            issue.map! do |error|
              lines = error.split("\n")
              # The following error is most likely irrelevant if there are more
              # than one messages per issue.
              # The first element is always the introduction:
              # 'The schema specific errors were:'
              # so the check count needs to be increased by one
              if lines.length > 2
                lines.reject! {
                  |l| l =~ /The property.*did not match one of the following values: deleted/
                }
              end
              lines.join("\n")
            end
          end

          issue
        else
          []
        end
      end

      errors.map! do |error|
        # optimize error message about unexpected values
        error.gsub!(/'#\/(\d+)\/([a-z\-]+)'/, "'\\2' of element #\\1")
        # optimize error message about missing required attributes
        error.gsub!(/The property '#\/(\d+).*?'/, "The element #\\1")
        # remove obsolete information at the end of the error message
        error.gsub(/ in schema .*$/, ".")
      end

      if !errors.empty?
        raise Machinery::Errors::SystemDescriptionError.new(errors.join("\n"))
      end

      @@json_validator.each do |json_path, block|
        pointer = JsonPointer.new(json, json_path, :symbolize_keys => false)
        block.yield pointer.value if pointer.exists?
      end
    end
  end

  GLOBAL_SCHEMA = load_global_schema
  SCOPE_SCHEMAS = load_scope_schemas

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

  def ensure_compatibility!
    if !compatible?
      raise Machinery::Errors::SystemDescriptionError.new(
        "The system description #{name} has an incompatible data format and can" \
        " not be read."
      )
    end
  end

  def to_json
    meta = {}
    meta["format_version"] = self.format_version if self.format_version

    attributes.each do |key, value|
      meta[key] = self[key].meta.as_json if self[key].meta
    end

    hash = as_json
    hash["meta"] = meta unless meta.empty?

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

    begin
      Os.for(self.os.name)
    rescue Machinery::Errors::UnknownOs => e
      raise Machinery::Errors::SystemDescriptionError.new(e)
    end
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
