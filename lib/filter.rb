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

# The Filter class is used to hold the information about the filter conditions
# that should be applied during certain Machinery commands.
#
# Filters are usually created by passing a filter definition string to the
# constructor, e.g.
#
#   filter = Filter.new("/unmanaged_files/files/name=/opt")
#
# Existing filters can be extended by amending the definition:
#
#   filter.add_element_filter_from_definition("/unmanaged_files/files/name=/srv")
#
# or by adding ElementFilters directly:
#
#   element_filter = ElementFilter.new("/unmanaged_files/files/name", ["/opt", "/srv"])
#   filter.add_element_filter(element_filter)
#
#
# The actual filtering can be done by passing values to Filter#matches?
#
#   filter = Filter.new("/unmanaged_files/files/name=/opt*")
#   filter.matches?("/unmanaged_files/files/name", "/opt/foo")
#   => true
#   filter.matches?("/unmanaged_files/files/name", "/srv/bar")
#   => false
#
# More details about how the filter work can be found at
# https://github.com/SUSE/machinery/blob/master/docs/Filtering-Design.md
class Filter
  attr_accessor :element_filters

  def self.parse_filter_definition(filter_definition)
    element_filters = {}
    filter_definition.scan(/\"([^,]*?)=([^\"]*)\"|([^,]+)=([^=]*)$|([^,]+)=([^,]*)/).
      map(&:compact).each do |path, matcher_definition|
        element_filters[path] ||= ElementFilter.new(path)
        if matcher_definition.index(",")
          element_filters[path].add_matchers([matcher_definition.split(",")])
        else
          element_filters[path].add_matchers(matcher_definition)
        end
    end

    element_filters
  end

  def initialize(filter_definition = "")
    @element_filters = Filter.parse_filter_definition(filter_definition)
  end

  def add_element_filter_from_definition(filter_definition)
    new_element_filters = Filter.parse_filter_definition(filter_definition)

    new_element_filters.each do |path, element_filter|
      @element_filters[path] ||= ElementFilter.new(path)
      @element_filters[path].add_matchers(element_filter.matchers)
    end
  end

  def add_element_filter(element_filter)
    path = element_filter.path
    @element_filters[path] ||= ElementFilter.new(path)
    @element_filters[path].add_matchers(element_filter.matchers)
  end

  def to_array
    @element_filters.flat_map do |path, element_filter|
      element_filter.matchers.map do |matcher|
        "#{path}=#{Array(matcher).join(",")}"
      end
    end
  end

  def matches?(path, value)
    filter = element_filter_for(path)
    return false if !filter

    filter.matches?(value)
  end

  def element_filter_for(path)
    element_filters[path]
  end
end
