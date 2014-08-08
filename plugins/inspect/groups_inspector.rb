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

class GroupsInspector < Inspector
  def inspect(system, description, options = {})
    group_content = system.cat_file("/etc/group")

    groups = group_content ? parse_groups(group_content) : []

    description.groups = GroupsScope.new(groups.sort_by(&:name))
    "Found #{groups.size} groups."
  end

  private

  def parse_groups(content)
    content.lines.map do |line|
      name, password, gid, users = line.split(":").map(&:chomp)

      attrs = {
        name: name,
        password: password,
        users: users.split(",")
      }
      attrs[:gid] = gid.to_i if !gid.empty?

      Group.new(attrs)
    end
  end
end
