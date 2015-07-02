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
    only_self = self - other
    only_other = other - self
    common = self & other

    changed_package_names = only_self.map(&:name) & only_other.map(&:name)
    changed = []

    changed_package_names.each do |name|
      changed << [
        only_self.find { |package| package.name == name },
        only_other.find { |package| package.name == name },
      ]
      only_self.reject! { |package| package.name == name }
      only_other.reject! { |package| package.name == name }
    end

    [
      only_self,
      only_other,
      changed,
      common
    ].map { |e| (e && !e.empty?) ? e : nil }
  end
end
