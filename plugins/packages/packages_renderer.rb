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

class PackagesRenderer < Renderer
  def display_name
    "Packages"
  end

  def content(description)
    return unless description.packages

    if description.packages.elements.empty?
      puts "There are no packages."
    end

    list do
      description.packages.each do |p|
        item "#{p.name}-#{p.version}-#{p.release}.#{p.arch} (#{p.vendor})"
      end
    end
  end

  # In the comparison case we only want to show the package name, not all details like version,
  # architecture etc.
  def compare_content_only_in(description)
    return if description.packages.empty?

    list do
      description.packages.each do |p|
        item "#{p.name}"
      end
    end
  end

  def compare_content_changed(changed_elements)
    list do
      changed_elements.each do |one, two|
        changes = []
        relevant_attributes = ["version", "vendor", "arch"]
        if one.version == two.version
          relevant_attributes << "release"
          relevant_attributes << "checksum" if one.release == two.release
        end

        relevant_attributes.each do |attribute|
          if one[attribute] != two[attribute]
            changes << "#{attribute}: #{one[attribute]} <> #{two[attribute]}"
          end
        end

        item "#{one.name} (#{changes.join(", ")})"
      end
    end
  end
end
