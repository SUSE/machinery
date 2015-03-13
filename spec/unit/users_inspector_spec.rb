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

describe UsersInspector do
  let(:description) {
    SystemDescription.new("systemname", SystemDescriptionStore.new)
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
  let(:filter) { nil }
  subject { UsersInspector.new }

  describe "#inspect" do
    it "return an empty list when /etc/passwd is missing" do
      expect(system).to receive(:read_file).with("/etc/passwd").and_return(nil)
      expect(system).to receive(:read_file).with("/etc/shadow").and_return(nil)

      subject.inspect(system, description, filter)
      expect(description.users).to be_empty
      expect(subject.summary(description)).to eq("Found 0 users.")
    end

    it "returns all attributes when /etc/shadow is present" do
      expect(system).to receive(:read_file).with("/etc/passwd").and_return(passwd_content)
      expect(system).to receive(:read_file).with("/etc/shadow").and_return(shadow_content)

      expected = UsersScope.new([
        User.new(
          name:               "lp",
          password:           "x",
          uid:                4,
          gid:                7,
          comment:            "Printing daemon",
          home:               "/var/spool/lpd",
          shell:              "/bin/false",
          encrypted_password: "*",
          last_changed_date:  16125,
          min_days:           1,
          max_days:           2,
          warn_days:          3,
          disable_days:       4,
          disabled_date:      5
        ),
        User.new(
          name:               "root",
          password:           "x",
          uid:                0,
          gid:                0,
          comment:            "root",
          home:               "/root",
          shell:              "/bin/bash",
          encrypted_password: "$1$Qf2FvbHa$sQCyvYhJKsCqAoTcK21eN1",
          last_changed_date:  16125
        )
      ])

      subject.inspect(system, description, filter)

      expect(description.users).to eq(expected)
      expect(subject.summary(description)).to eq("Found 2 users.")
    end

    it "it can deal with the NIS placeholder in /etc/passwd" do
      expect(system).to receive(:read_file).with("/etc/passwd").and_return("+::::::\n")
      expect(system).to receive(:read_file).with("/etc/shadow").and_return("+::0:0:0::::\n")

      expected = UsersScope.new([
        User.new(
          name:               "+",
          password:           "",
          uid:                nil,
          gid:                nil,
          comment:            "",
          home:               "",
          shell:              "",
          encrypted_password: "",
          last_changed_date:  0,
          min_days:           0,
          max_days:           0
        )
      ])

      subject.inspect(system, description, filter)

      expect(description.users).to eq(expected)
    end

    it "returns all available attributes when /etc/shadow is missing" do
      expect(system).to receive(:read_file).with("/etc/passwd").and_return(passwd_content)
      expect(system).to receive(:read_file).with("/etc/shadow").and_return(nil)

      expected = UsersScope.new([
        User.new(
          name:            "lp",
          password:        "x",
          uid:             4,
          gid:             7,
          comment:         "Printing daemon",
          home:            "/var/spool/lpd",
          shell:           "/bin/false"
        ),
        User.new(
          name:            "root",
          password:        "x",
          uid:             0,
          gid:             0,
          comment:         "root",
          home:            "/root",
          shell:           "/bin/bash"
        )
      ])

      subject.inspect(system, description, filter)

      expect(description.users).to eq(expected)
      expect(subject.summary(description)).to eq("Found 2 users.")
    end

    it "returns sorted data" do
      expect(system).to receive(:read_file).with("/etc/passwd").and_return(passwd_content)
      expect(system).to receive(:read_file).with("/etc/shadow").and_return(nil)

      subject.inspect(system, description, filter)
      names = description.users.map(&:name)
      expect(names).to eq(names.sort)
    end
  end
end
