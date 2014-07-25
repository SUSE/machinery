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

describe UsersInspector do
  let(:description) {
    SystemDescription.new("systemname", {}, SystemDescriptionStore.new)
  }
  let(:passwd_content) {<<EOF
root:x:0:0:root:/root:/bin/bash
lp:x:4:7:Printing daemon:/var/spool/lpd:/bin/false
EOF
  }
  let(:shadow_content) {<<EOF
root:$1$Qf2FvbHa$sQCyvYhJKsCqAoTcK21eN1:16125::::::
lp:*:16125:1:2:3:4:5
EOF
  }
  let(:system) { double }
  subject { UsersInspector.new }

  describe "#inspect" do
    it "return an empty list when /etc/passwd is missing" do
      expect(system).to receive(:cat_file).with("/etc/passwd").and_return(nil)
      expect(system).to receive(:cat_file).with("/etc/shadow").and_return(nil)

      summary = subject.inspect(system, description)
      expect(description.users).to be_empty
      expect(summary).to eq("Found 0 users.")
    end

    it "returns all attributes when /etc/shadow is present" do
      expect(system).to receive(:cat_file).with("/etc/passwd").and_return(passwd_content)
      expect(system).to receive(:cat_file).with("/etc/shadow").and_return(shadow_content)

      expected = UsersScope.new([
        User.new(
          name:            "lp",
          password:        "x",
          uid:             "4",
          gid:             "7",
          info:            "Printing daemon",
          home:            "/var/spool/lpd",
          shell:           "/bin/false",
          shadow_password: "*",
          last_changed:    "16125",
          minimum_age:     "1",
          maximum_age:     "2",
          warn_days:       "3",
          expire_inactive: "4",
          expire:          "5"
        ),
        User.new(
          name:            "root",
          password:        "x",
          uid:             "0",
          gid:             "0",
          info:            "root",
          home:            "/root",
          shell:           "/bin/bash",
          shadow_password: "$1$Qf2FvbHa$sQCyvYhJKsCqAoTcK21eN1",
          last_changed:    "16125",
          minimum_age:     "",
          maximum_age:     "",
          warn_days:       "",
          expire_inactive: "",
          expire:          ""
        )
      ])

      summary = subject.inspect(system, description)

      expect(description.users).to eq(expected)
      expect(summary).to eq("Found 2 users.")
    end

    it "returns all available attributes when /etc/shadow is missing" do
      expect(system).to receive(:cat_file).with("/etc/passwd").and_return(passwd_content)
      expect(system).to receive(:cat_file).with("/etc/shadow").and_return(nil)

      expected = UsersScope.new([
        User.new(
          name:            "lp",
          password:        "x",
          uid:             "4",
          gid:             "7",
          info:            "Printing daemon",
          home:            "/var/spool/lpd",
          shell:           "/bin/false"
        ),
        User.new(
            name:            "root",
            password:        "x",
            uid:             "0",
            gid:             "0",
            info:            "root",
            home:            "/root",
            shell:           "/bin/bash"
        )
      ])

      summary = subject.inspect(system, description)

      expect(description.users).to eq(expected)
      expect(summary).to eq("Found 2 users.")
    end

    it "returns sorted data" do
      expect(system).to receive(:cat_file).with("/etc/passwd").and_return(passwd_content)
      expect(system).to receive(:cat_file).with("/etc/shadow").and_return(nil)

      subject.inspect(system, description)
      names = description.users.map(&:name)
      expect(names).to eq(names.sort)
    end
  end
end
