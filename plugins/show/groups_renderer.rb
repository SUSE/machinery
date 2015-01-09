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

class GroupsRenderer < Renderer
  def do_render
    return unless @system_description.groups

    list do
      @system_description.groups.each do |group|
        gid = group.gid || "N/A"
        details ="gid: #{gid}"
        details += ", users: #{group.users.join(",")}" if !group.users.empty?

        item "#{group.name} (#{details})"
      end
    end
  end

  def display_name
    "Groups"
  end
end
