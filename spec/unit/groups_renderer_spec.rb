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

describe GroupsRenderer do
  let(:system_description) {
    json = <<-EOF
    {
      "groups": [
        {
          "name": "root",
          "password": "x",
          "gid": "0",
          "users": []
        },
        {
          "name": "tftp",
          "password": "x",
          "gid": "7",
          "users": ["dnsmasq", "tftp"]
        }
      ]
    }
    EOF
    SystemDescription.from_json("name", json)
  }

  describe "show" do
    it "prints a repository list" do
      output = GroupsRenderer.new.render(system_description)

      expect(output).to include("root (gid: 0)")
      expect(output).to include("tftp (gid: 7, users: dnsmasq,tftp)")
    end
  end
end
