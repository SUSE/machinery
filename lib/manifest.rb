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

# The Manifest class takes care of handling the JSON representation of system
# descriptions. It loads and parses the JSON into a hash and validates it against
# the current schema.
class Manifest
  attr_accessor :name, :path, :json, :hash

  def self.load(name, path)
    unless File.exists?(path)
      raise Machinery::Errors::SystemDescriptionNotFound.new(
        "A system description with the name #{name} was not found."
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
    return if !compatible_json?

    errors = SystemDescriptionValidator.new(self).validate_json(@hash)
    if !errors.empty?
      Machinery::Ui.warn("Warning: System Description validation errors:")
      Machinery::Ui.warn(errors)
    end
  end

  def validate!
    return if !compatible_json?

    errors = SystemDescriptionValidator.new(self).validate_json(@hash)
    if !errors.empty?
      raise Machinery::Errors::SystemDescriptionError.new(errors.join("\n"))
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
    error += " in file '#{path}'" if path
    error += ":\n\n#{json_error}"

    raise Machinery::Errors::SystemDescriptionError.new(error)
  end

  def compatible_json?
    @hash.is_a?(Hash) && @hash["meta"].is_a?(Hash) && @hash["meta"]["format_version"]
  end
end
