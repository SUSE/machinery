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

class UnmanagedFilesRenderer < Renderer
  def content(description)
    return unless description["unmanaged_files"]

    list do
      file_status = description["unmanaged_files"].extracted

      if description["unmanaged_files"].files.empty?
        puts "There are no unmanaged files."
      elsif !file_status.nil?
        puts "Files extracted: #{file_status ? "yes" : "no"}"
      end

      if description["unmanaged_files"].files
        description["unmanaged_files"].files.each do |p|
          if description["unmanaged_files"].extracted
            item "#{p.name} (#{p.type})" do
              puts "User/Group: #{p.user}:#{p.group}" if p.user || p.group
              puts "Mode: #{p.mode}" if p.mode
              puts "Size: #{number_to_human_size(p.size)}" if p.size
              puts "Files: #{p.files}" if p.files
            end
          else
            item "#{p.name} (#{p.type})"
          end
        end
      end
    end
  end

  def display_name
    "Unmanaged files"
  end

  def compare_content_changed(changed_elements)
    list do
      changed_elements.each do |one, two|
        changes = []
        relevant_attributes = (one.attributes.keys & two.attributes.keys)

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
