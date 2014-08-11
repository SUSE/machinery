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

module ChangedRpmFilesHelper
  def parse_rpm_changes_line(line)
    # rpm provides lines per config file where first 9 characters indicate which
    # properties of the file are modified
    rpm_changes, *fields = line.split(" ")

    # For config or documentation files there's an additional field which
    # contains "c" or "d"
    type = fields[0].start_with?("/") ? "" : fields.shift
    path = fields.join(" ")

    changes = []
    if rpm_changes == "missing"
      changes << "deleted"
    elsif rpm_changes == "........." && path.end_with?(" (replaced)")
      changes << "replaced"
      path.slice!(/ \(replaced\)$/)
    else
      changes << "mode" if rpm_changes[1] == "M"
      changes << "md5" if rpm_changes[2] == "5"
      changes << "user" if rpm_changes[5] == "U"
      changes << "group" if rpm_changes[6] == "G"
    end
    [path, changes, type]
  end

  def parse_stat_line(line)
    mode, user, group, uid, gid, *path = line.split(":")

    user = uid if user == "UNKNOWN"
    group = gid if group == "UNKNOWN"

    [path.join(":").chomp,
      {
        :mode  => mode,
        :user  => user,
        :group => group
      }
    ]
  end

  # get path data for list of files
  # cur_files is guaranteed to not exceed max command line length
  def get_file_properties(system, cur_files)
    ret = {}
    out = system.run_command(
        "stat", "--printf", "%a:%U:%G:%u:%g:%n\\n",
        *cur_files,
        :stdout => :capture
    )
    out.each_line do |l|
      path, values = parse_stat_line(l)
      ret[path] = values
    end
    ret
  end

  def get_path_data(system, paths)
    ret = {}
    path_index = 0
    # arbitrary number for maximum command line length that should always work
    max_len = 50000
    cur_files = []
    cur_len = 0
    while path_index < paths.size
      if cur_files.empty? || paths[path_index].size + cur_len + 1 < max_len
        cur_files << paths[path_index]
        cur_len += paths[path_index].size + 1
        path_index += 1
      else
        ret.merge!(get_file_properties(system, cur_files))
        cur_files.clear
        cur_len = 0
      end
    end
    ret.merge!(get_file_properties(system, cur_files)) unless cur_files.empty?
    ret
  end
end
