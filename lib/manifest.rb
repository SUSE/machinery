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

# The Manifest class takes care of handling the JSON representation of system
# descriptions. It loads and parses the JSON into a hash and validates it against
# the current schema.
class Manifest
  attr_accessor :name, :path, :json, :hash

  def self.load(name, path)
    unless File.exist?(path)
      raise Machinery::Errors::SystemDescriptionNotFound.new(
        "Couldn't find a system description with the name '#{name}'."
      )
    end

    json = File.read(path)
    Manifest.new(name, json, path)
  end

  def initialize(name, json, path = nil)
    @name = name
    @path = path
    @json = json

    parse
  end

  def validate
    return unless compatible_json?

    errors = JsonValidator.new(@hash).validate
    unless errors.empty?
      Machinery::Ui.warn("Warning: System Description validation errors:")
      Machinery::Ui.warn(errors.join("\n"))
    end
  end

  def validate!
    return unless compatible_json?

    errors = JsonValidator.new(@hash).validate
    unless errors.empty?
      raise Machinery::Errors::SystemDescriptionValidationFailed.new(errors)
    end
  end

  def to_hash
    @hash
  end

  private

  def parse
    @hash = JSON.parse(@json)
  rescue JSON::ParserError => e
    lines = e.message.split("\n")
    error_pos = json.split("\n").length - lines.length + 2
    block_end = lines.index { |l| l =~ / [\}\]],?$/ }

    # remove needless json error information
    lines[0].gsub!(/^\d+: (.*)$/, "\\1")

    if error_pos == 1
      json_error = "An opening bracket, a comma or quotation is missing " \
              "in one of the global scope definitions or in the meta section. " \
              "Unlike issues with the elements of the scopes, our JSON parser " \
              "isn't able to locate issues like these."
      error_pos = nil
    end

    json_error ||= lines[0..block_end].join("\n")

    error = "The JSON data of the system description '#{name}' " \
            "couldn't be parsed. The following error occured"
    error += " around line #{error_pos}" if error_pos
    error += " in file '#{path}'" if path
    error += ":\n\n#{json_error}"

    raise Machinery::Errors::SystemDescriptionError.new(error)
  end

  def compatible_json?
    @hash && @hash["meta"] && @hash["meta"]["format_version"] &&
      @hash["meta"]["format_version"] <= SystemDescription::CURRENT_FORMAT_VERSION
  end
end
