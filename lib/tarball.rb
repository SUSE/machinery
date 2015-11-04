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

# Represents a tarball, possibly gzipped.
class Tarball
  def initialize(file)
    @file = file
  end

  def list
    output = LoggedCheetah.run("tar", "tvf", @file, "--quoting-style=literal", stdout: :capture)

    output.lines.map do |line|
      mode, user_and_group, size, _date, _time, rest = line.split(" ", 6)

      case mode[0]
      when "l"
        type = :link
        # This may fail for files with "->" in their name, but there is no way
        # how to avoid this when using "tar".
        path = rest.split(" -> ").first
      when "h"
        type = :file
        # This may fail for files with "link to" in their name, but there is no way
        # how to avoid this when using "tar" unless we use the parameter
        # --hard-dereference with tar to get rid of hard links
        path = rest.split(" link to ").first
      when "d"
        type = :dir
        path = rest.chomp("/\n")
      else
        type = :file
        path = rest.chomp
      end

      user, group = user_and_group.split("/")

      {
        path:  path,
        type:  type,
        size:  size.to_i,
        mode:  mode_string_to_octal(mode),
        user:  user,
        group: group
      }
    end
  end

  private

  def mode_string_to_octal(mode)
    result = 0

    # The following code is intentionally stupid.

    result |= 00001 if mode[9] == "x" || mode[9] == "t"
    result |= 00002 if mode[8] == "w"
    result |= 00004 if mode[7] == "r"

    result |= 00010 if mode[6] == "x" || mode[6] == "s"
    result |= 00020 if mode[5] == "w"
    result |= 00040 if mode[4] == "r"

    result |= 00100 if mode[3] == "x" || mode[3] == "s"
    result |= 00200 if mode[2] == "w"
    result |= 00400 if mode[1] == "r"

    result |= 01000 if mode[9] == "t" || mode[9] == "T"
    result |= 02000 if mode[6] == "s" || mode[6] == "S"
    result |= 04000 if mode[3] == "s" || mode[3] == "S"

    result.to_s(8).rjust(3, "0")
  end
end
