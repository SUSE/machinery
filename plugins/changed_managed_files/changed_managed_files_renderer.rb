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

class ChangedManagedFilesRenderer < Renderer
  def content(description)
    return unless description["changed_managed_files"]

    if description["changed_managed_files"].files
      files, errors = description["changed_managed_files"].files.partition do |file|
        file.status != "error"
      end
    end

    list do
      file_status = description["changed_managed_files"].extracted
      if !file_status.nil?
        puts "Files extracted: #{file_status ? "yes" : "no"}"
      end

      if files && files.empty?
        puts "There are no changed managed files."
      end

      if files && !files.empty?
        files.each do |p|
          item "#{p.name} (#{p.changes.join(", ")})"
        end
      end
    end

    if errors && !errors.empty?
      list("Errors") do
        errors.each do |p|
          item "#{p.name}: #{p.error_message}"
        end
      end
    end
  end

  def display_name
    "Changed managed files"
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
