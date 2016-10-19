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

class GroupsInspector < Machinery::Inspector
  has_priority 60

  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(_filter, _options = {})
    group_content = @system.read_file("/etc/group")

    groups = group_content ? parse_groups(group_content) : []

    @description.groups = GroupsScope.new(groups.sort_by(&:name))
  end

  def summary
    "Found #{Machinery.pluralize(@description.groups.size, "%d group")}."
  end

  private

  def parse_groups(content)
    content.lines.map do |line|
      # prevent split from ignoring the last entry if it is empty and there is no newline
      line += "\n" if line.end_with?(":")
      name, password, gid, users = line.split(":").map(&:chomp)

      gid = Machinery::is_int?(gid) ? gid.to_i : nil

      attrs = {
        name: name,
        password: password,
        gid: gid,
        users: users.split(",")
      }

      Group.new(attrs)
    end
  end
end
