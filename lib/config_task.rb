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

class ConfigTask
  def initialize(config = Machinery::Config.new)
    @config = config
  end

  def config(key = nil, value_string = nil)
    if !key
      # show all config entries
      @config.each do |key, value|
        Machinery::Ui.puts "#{key}=#{value[:value]} (#{value[:description]})"
      end
    elsif !value_string
      # show one specific config entry
      Machinery::Ui.puts "#{key}=#{@config.get(key)}"
    else
      # set one specific config entry
      @config.set(key, parse_value_string(key, value_string))
      Machinery::Ui.puts "#{key}=#{@config.get(key)}"
    end
  end

  def parse_value_string(key, value_string)
    current_value = @config.get(key)

    if current_value == true || current_value == false
      if value_string == "true" || value_string == "on"
        return true
      elsif value_string == "false" || value_string == "off"
        return false
      else
        raise Machinery::Errors::MachineryError.new(
          "The value '#{value_string}' is not valid for key '#{key}'." \
            " Please enter a valid variable of type boolean."
        )
      end
    elsif current_value.kind_of?(Integer)
      return value_string.to_i
    else
      return value_string
    end
  end
end
