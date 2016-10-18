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

class UsersRenderer < Machinery::Ui::Renderer
  def content(description)
    return unless description.users

    if description.users.any? { |a| a[:comment] == "" || a[:uid].nil? || a[:gid].nil? }
      na_note("user info, user ID or group ID")
    end

    list do
      description.users.each do |user|
        info = user.comment.empty? ? "N/A" : user.comment
        uid = user.uid || "N/A"
        gid = user.gid || "N/A"
        item "#{user.name} (#{info}, uid: #{uid}, gid: #{gid}, shell: #{user.shell})"
      end
    end
  end

  def display_name
    "Users"
  end

  def compare_content_changed(changed_elements)
    list do
      changed_elements.each do |one, two|
        changes = []
        relevant_attributes = ["uid", "gid", "comment", "shell", "home"]

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
