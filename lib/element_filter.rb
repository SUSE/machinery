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

class ElementFilter
  attr_accessor :path, :matchers

  def initialize(path, matchers = nil)
    @path = path
    @matchers = []

    raise("Wrong type") if ![NilClass, String, Array].include?(matchers.class)

    add_matchers(matchers) if matchers
  end

  def add_matchers(matchers)
    @matchers += Array(matchers)
  end

  def matches?(value)
    @matchers.each do |matcher|
      case matcher
      when Array
        value_array = value.elements
        return true if (value_array - matcher).empty? && (matcher - value_array).empty?
      when String
        if matcher.end_with?("*")
          return true if value.start_with?(matcher[0..-2])
        else
          return true if value == matcher
        end
      end
    end

    false
  end
end
