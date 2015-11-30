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


class Package < Machinery::Object
end

class PackagesScope < Machinery::Array
  include Machinery::Scope

  has_elements class: Package

  def compare_with(other)
    if self.package_system != other.package_system
      [self, other, nil, nil]
    else
      only_self = self - other
      only_other = other - self
      common = self & other
      changed = Machinery::Scope.extract_changed_elements(only_self, only_other, :name)
      changed = nil if changed.empty?

      [
        package_list_to_scope(only_self),
        package_list_to_scope(only_other),
        changed,
        package_list_to_scope(common)
      ].map { |e| (e && !e.empty?) ? e : nil }
    end
  end

  private

  def package_list_to_scope(packages)
    self.class.new(packages, package_system: package_system) unless packages.empty?
  end
end
