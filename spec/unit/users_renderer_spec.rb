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

require_relative "spec_helper"

describe UsersRenderer do
  let(:system_description) {
    json = <<-EOF
    {
      "users": [
        {
          "name": "root",
          "password": "$1$Qf2FvbHa$sQCyvYhJKsCqAoTcK21eN1",
          "uid": null,
          "gid": null,
          "comment": "",
          "home": "/root",
          "shell": "/bin/bash",
          "last_changed": 16125
        },
        {
          "name": "lp",
          "password": "*",
          "uid": 4,
          "gid": 7,
          "comment": "Printing daemon",
          "home": "/var/spool/lpd",
          "shell": "/bin/bash",
          "last_changed": 16125
        }
      ]
    }
    EOF
    SystemDescription.from_json("name", json)
  }

  describe "show" do
    it "prints the user list" do
      output = UsersRenderer.new.render(system_description)

      expect(output).to include("root (N/A, uid: N/A, gid: N/A, shell: /bin/bash)")
      expect(output).to include("lp (Printing daemon, uid: 4, gid: 7, shell: /bin/bash)")
    end
  end
end
