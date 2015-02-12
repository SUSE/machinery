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

class JsonValidator
  class <<self
    def validate(schema, hash)
      JSON::Validator.fully_validate(schema, hash)
    end

    def validate_scope(schema, hash, scope)
      errors = JSON::Validator.fully_validate(schema, hash).map do |error|
        "In scope #{scope}: #{error}"
      end
      errors.map do |error|
        cleanup_json_error_message(error, scope)
      end
    end

    def cleanup_json_error_message(message, scope)
      message = cleanup_json_path(message, scope)
      message = remove_json_error_uuid(message)
      message
    end

    private

    def cleanup_json_path(message, scope)
      old_path = message[/The property '#\/(.*?)'/,1]

      position = error_position_from_json_path(old_path)
      details = extract_details_from_json_path(old_path, scope)

      new_path = "The property"
      new_path += " ##{position}" if position > -1
      new_path += " (#{details})" if !details.empty?

      message.gsub(/The property '#\/.*?'/, new_path)
    end

    def error_position_from_json_path(path)
      elements = path.split("/")

      position = -1
      elements.each do |e|
        if Machinery::is_int?(e)
          number = e.to_i
          position = number if number > position
        end
      end
      position
    end

    def extract_details_from_json_path(path, scope)
      elements = path.split("/")

      elements.uniq!

      # filter numbers since the position is calculated elswhere
      elements.reject! { |e| Machinery::is_int?(e) }

      # The json schema path often contains the word "type" in many messages
      # but this information adds no value for the user since it is not related
      # to our manifest.json
      # So we filter it for all scopes except of repositories since this is the
      # only scope which does have an attribute called "type"
      if scope != "repositories"
        elements.reject! { |e| e == "type" }
      end

      elements.join("/")
    end

    def remove_json_error_uuid(message)
      message.gsub(/ in schema .*$/, ".")
    end

  end
end
