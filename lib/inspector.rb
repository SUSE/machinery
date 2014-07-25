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
class Inspector
  abstract_method :inspect

  @inspectors = []

  class << self
    def inherited(klass)
      @inspectors << klass
    end

    def for(scope)
      class_name = "#{scope.split("-").map(&:capitalize).join}Inspector"

      Object.const_get(class_name).new if Object.const_defined?(class_name)
    end

    def all
      @inspectors.map(&:new)
    end

    def all_scopes
      all.map(&:scope)
    end
  end

  def scope
    # Return the un-camelcased name of the inspector,
    # e.g. "foo-bar" for "FooBarInspector"
    scope = self.class.name.match(/^(.*)Inspector$/)[1]
    scope.gsub(/([^A-Z])([A-Z])/, "\\1-\\2").downcase
  end
end
