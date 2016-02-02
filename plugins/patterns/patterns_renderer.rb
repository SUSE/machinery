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

class PatternsRenderer < Renderer
  def content(description)
    return unless description.patterns

    if description.patterns.empty?
      puts "There are no patterns."
    end

    list do
      description.patterns.each do |p|
        item "#{p.name}"
      end
    end
  end

  def display_name
    "Patterns"
  end

  def compare_content_changed(changed_elements)
    list do
      changed_elements.each do |one, two|
        changes = []
        relevant_attributes = ["version"]

        if one.version == two.version
          relevant_attributes << "release"
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
