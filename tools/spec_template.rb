# encoding:utf-8

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

class SpecTemplate
  attr_accessor   :version
  attr_accessor   :dependencies

  def initialize(version, gemspec)
    @version      = version
    @gemspec      = gemspec
    @dependencies = @gemspec.runtime_dependencies
  end

  def build_requires(options = {})
    @gemspec.runtime_dependencies.flat_map { |d| gem_dependency_to_rpm_requires(d) }.flatten
  end

  private

  def gem_dependency_to_rpm_requires(dependency)
    name = dependency.name

    dependency.requirement.requirements.map do |operator, version|
      case operator
        when "!="
          [
            { :name => name, :operator => "<", :version => version },
            { :name => name, :operator => ">", :version => version }
          ]
        when "~>"
          if version.to_s.split(".").size > 1
            [
              { :name => name, :operator => ">=", :version => version },
              { :name => name, :operator => "<=", :version => version.bump }
            ]
          else
            { :name => name }
          end
        else
          { :name => name, :operator => operator, :version => version }
      end
    end
  end
end
