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

require_relative "spec_helper"

describe Tarball do
  describe "#list" do
    it "returns a list of files in the tarball with attributes" do
      tarball = Tarball.new(
        File.join(Machinery::ROOT, "spec/data/tarball/tarball.tar.gz")
      )

      expect(tarball.list).to match_array([
        { path: "dir",         type: :dir,  size:  0, mode:  "755", user: "nobody", group: "users" },
        { path: "file",        type: :file, size: 10, mode:  "644", user: "nobody", group: "users" },
        { path: "hardlink",    type: :file, size:  0, mode:  "644", user: "nobody", group: "users" },
        {
          path: "lot_of_spaces                           .txt",
          type: :file,
          size: 0,
          mode: "644",
          user: "nobody",
          group: "users"
        },
        { path: "perms-0000",  type: :file, size:  0, mode:  "000", user: "nobody", group: "users" },
        { path: "perms-0001",  type: :file, size:  0, mode:  "001", user: "nobody", group: "users" },
        { path: "perms-0002",  type: :file, size:  0, mode:  "002", user: "nobody", group: "users" },
        { path: "perms-0004",  type: :file, size:  0, mode:  "004", user: "nobody", group: "users" },
        { path: "perms-0010",  type: :file, size:  0, mode:  "010", user: "nobody", group: "users" },
        { path: "perms-0020",  type: :file, size:  0, mode:  "020", user: "nobody", group: "users" },
        { path: "perms-0040",  type: :file, size:  0, mode:  "040", user: "nobody", group: "users" },
        { path: "perms-0100",  type: :file, size:  0, mode:  "100", user: "nobody", group: "users" },
        { path: "perms-0200",  type: :file, size:  0, mode:  "200", user: "nobody", group: "users" },
        { path: "perms-0400",  type: :file, size:  0, mode:  "400", user: "nobody", group: "users" },
        { path: "perms-1000",  type: :file, size:  0, mode: "1000", user: "nobody", group: "users" },
        { path: "perms-1001",  type: :file, size:  0, mode: "1001", user: "nobody", group: "users" },
        { path: "perms-2000",  type: :file, size:  0, mode: "2000", user: "nobody", group: "users" },
        { path: "perms-2010",  type: :file, size:  0, mode: "2010", user: "nobody", group: "users" },
        { path: "perms-4000",  type: :file, size:  0, mode: "4000", user: "nobody", group: "users" },
        { path: "perms-4100",  type: :file, size:  0, mode: "4100", user: "nobody", group: "users" },
        { path: "softlink",    type: :link, size:  0, mode:  "777", user: "nobody", group: "users" },
        { path: "s p a c e s", type: :file, size:  0, mode:  "644", user: "nobody", group: "users" },
        { path: "\\", type: :dir, size:  0, mode:  "700", user: "nobody", group: "users" },
      ])
    end
  end
end
