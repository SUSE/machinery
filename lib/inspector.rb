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

# This is the base class for all the "inspect" plugin classes. It keeps
# track of the loaded subclasses and allows for querying plugins for a
# given scope or all available ones.
#
# The names of the subclasses are 1:1 mappings of the inspection areas, e.g.
# the PackagesInspector class would be used for inspection when the user
# specifies "--scope=packages".
#
# All subclasses have to implement the
#
#   inspect(system, description)
#
# method which inspects the given system and stores the gathered information in
# the description. It returns a brief summary string of the inspection.
#
# The description object can also be used to store files in the description.
class Machinery::Inspector
  abstract_method :inspect
  abstract_method :summary

  @inspectors = []

  class << self
    def priority
      @priority || 1000
    end

    def has_priority(value)
      @priority = value
    end

    def inherited(klass)
      @inspectors << klass
    end

    def for(scope)
      class_name = "Machinery::#{scope.split("_").map(&:capitalize).join}Inspector"

      Object.const_get(class_name) if Object.const_defined?(class_name)
    end

    def all
      @inspectors
    end

    def all_scopes
      sort_scopes(all.map(&:scope))
    end

    def sort_scopes(scope_list)
      scope_priority = {}

      visible_scopes = Machinery::Scope.visible_scopes.map(&:scope_name)
      scope_list.each do |scope|
        inspector = self.for(scope)
        next if !inspector || !visible_scopes.include?(scope)

        scope_priority[inspector.priority] = scope
      end

      scope_priority.sort.map do |key, value|
        scope_priority[key] = value
      end
    end

    def scope
      # Return the un-camelcased name of the inspector,
      # e.g. "foo_bar" for "FooBarInspector"
      scope = name.match(/^Machinery::(.*)Inspector$/)[1]
      scope.gsub(/([^A-Z])([A-Z])/, "\\1_\\2").downcase
    end
  end

  attr_accessor :system, :description

  def scope
    self.class.scope
  end
end
