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

  def initialize(path, operator = nil, matchers = nil)
    @path = path
    @matchers = {}

    if ![NilClass, String, Array].include?(matchers.class)
      raise Machinery::Errors::InvalidFilter.new("Wrong filter type")
    end

    add_matchers(operator, matchers) if operator && matchers
  end

  def add_matchers(operator, matchers)
    if ![Filter::OPERATOR_EQUALS, Filter::OPERATOR_EQUALS_NOT].include?(operator)
      raise Machinery::Errors::InvalidFilter.new("Wrong filter operator '#{operator}'")
    end

    @matchers[operator] ||= []
    @matchers[operator] += Array(matchers)
  end

  def matches?(value)
    @matchers.each do |operator, matchers|
      matchers.each do |matcher|
        values_equal = case value
        when Machinery::Array
          value_array = value.elements

          (value_array - Array(matcher)).empty? && (Array(matcher) - value_array).empty?
        when String
          if matcher.is_a?(Array)
            exception = Machinery::Errors::ElementFilterTypeMismatch.new
            exception.failed_matcher =
              "#{path}#{operator}#{matcher.join(",")}"
            raise exception
          end

          if matcher.end_with?("*")
            value.start_with?(matcher[0..-2])
          else
            value == matcher
          end
        end
        if operator == Filter::OPERATOR_EQUALS
          return true if values_equal
        elsif operator == Filter::OPERATOR_EQUALS_NOT
          return true if !values_equal
        end
      end
    end

    false
  end

  def filters_scope?(scope)
    (path =~ /\/#{scope}(\/|$)/) ? true : false
  end

  def ==(other)
    path == other.path &&
      matchers == other.matchers
  end
end
