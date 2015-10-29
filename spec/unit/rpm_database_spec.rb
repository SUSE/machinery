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

describe RpmDatabase do
  describe RpmDatabase::ChangedFile do
    describe "config_file?" do
      it "returns true for config files" do
        file = RpmDatabase::ChangedFile.new(
          "c",
          name:    "/etc/foo",
          status:  "changed",
          changes: ["md5"]
        )
        expect(file.config_file?).to be(true)
      end

      it "returns false for non-config files" do
        file = RpmDatabase::ChangedFile.new(
          "",
          name:    "/etc/foo",
          status:  "changed",
          changes: ["md5"]
        )
        file.type = ""
        expect(file.config_file?).to be(false)
      end
    end
  end

  let(:system) { LocalSystem.new }
  let(:changed_files_sh_result) {
    File.read(File.join(Machinery::ROOT, "spec/data/rpm_database/changed_files_sh_result"))
  }
  subject { RpmDatabase.new(system) }

  describe "#changed_files" do
    before(:each) do
      allow(system).to receive(:run_script_with_progress).and_return(changed_files_sh_result)
      allow(system).to receive(:run_command).and_return("zypper-1.6.311-16.2.3.x86_64")
    end

    it "returns the list of files" do
      expected = RpmDatabase::ChangedFile.new(
        "",
        name:            "/etc/iscsi/iscsid.conf",
        status:          "changed",
        changes:         ["size", "mode", "md5", "user", "group", "time"],
        package_name:    "zypper",
        package_version: "1.6.311"
      )

      expect(subject.changed_files.first).to eq(expected)
      expect(subject.changed_files.length).to eq(7)
    end

    it "caches the result" do
      expect(system).to receive(:run_script_with_progress).and_return(changed_files_sh_result).once

      subject.changed_files
      subject.changed_files
    end
  end

  describe "parse_rpm_changes_line" do
    capture_machinery_output

    it "parses an md5 change" do
      line = "..5......  c /etc/pulse/client.conf"
      file, changes, flag = subject.parse_rpm_changes_line(line)
      expect(file).to eq("/etc/pulse/client.conf")
      expect(changes).to match_array(["md5"])
      expect(flag).to eq("c")
    end

    it "parses all changes" do
      line = "SM5DLUGTP  c /etc/pulse/client.conf"
      file, changes, flag = subject.parse_rpm_changes_line(line)
      expect(file).to eq("/etc/pulse/client.conf")
      expect(changes).to match_array([
        "size", "mode", "md5", "device_number", "link_path", "user", "group", "time", "capabilities"
      ])
      expect(flag).to eq("c")
    end

    it "parses all changes for sles11sp3" do
      line = "SM5DLUGT  c /etc/pulse/client.conf"
      file, changes, flag = subject.parse_rpm_changes_line(line)
      expect(file).to eq("/etc/pulse/client.conf")
      expect(changes).to match_array(
        ["size", "mode", "md5", "device_number", "link_path", "user", "group", "time"]
      )
      expect(flag).to eq("c")
    end

    it "parses an unknown change" do
      line = "........S  c /etc/pulse/client.conf"
      file, changes, flag = subject.parse_rpm_changes_line(line)
      expect(file).to eq("/etc/pulse/client.conf")
      expect(changes).to match_array(["other_rpm_changes"])
      expect(flag).to eq("c")
    end

    it "it adds other_rpm_changes in case of an unknown rpm change tag" do
      line = "S.......X  c /etc/pulse/client.conf"
      file, changes, flag = subject.parse_rpm_changes_line(line)
      expect(file).to eq("/etc/pulse/client.conf")
      expect(changes).to match_array(["size", "other_rpm_changes"])
      expect(flag).to eq("c")
    end

    it "it adds other_rpm_changes in case of an unexpected new/additional rpm tag" do
      line = "S........N  c /etc/pulse/client.conf"
      file, changes, flag = subject.parse_rpm_changes_line(line)
      expect(file).to eq("/etc/pulse/client.conf")
      expect(changes).to match_array(["size", "other_rpm_changes"])
      expect(flag).to eq("c")
    end

    it "shows a warning when an rpm test could not be performed but still adds known tags" do
      line = "S.?......  c /etc/pulse/client.conf"
      _, changes = subject.parse_rpm_changes_line(line)
      expect(changes).to match_array(["size"])
      expect(captured_machinery_output).to include("Warning: Could not perform all tests on "\
      "rpm changes for file '/etc/pulse/client.conf'.")
    end

    it "logs the warning when an rpm test could not be performed" do
      line = "..?......  c /etc/pulse/client.conf"
      expect(Machinery.logger).to receive(:warn).with("Could not perform all tests on "\
      "rpm changes for file '/etc/pulse/client.conf'.")
      subject.parse_rpm_changes_line(line)
    end
  end

  describe "#subject.parse_stat_line" do
    it "parses directories" do
      line = "755:root:users:0:0:directory:/etc/named.d/"
      expect(subject.parse_stat_line(line)).to eq(
        [
          "/etc/named.d/",
          {
            mode:  "755",
            user:  "root",
            group: "users",
            type:  "dir"
          }
        ]
      )
    end

    it "parses files" do
      line = "640:root:shadow:0:15:regular file:/etc/shadow"
      expect(subject.parse_stat_line(line)).to eq(
        [
          "/etc/shadow",
          {
            mode:  "640",
            user:  "root",
            group: "shadow",
            type:  "file"
          }
        ]
      )
    end

    it "uses uid and gid if user and group are unknown" do
      line = "640:UNKNOWN:UNKNOWN:0:15:regular file:/etc/shadow"
      expect(subject.parse_stat_line(line)).to eq(
        [
          "/etc/shadow",
          {
            mode:  "640",
            user:  "0",
            group: "15",
            type:  "file"
          }
        ]
      )
    end

    it "parses links" do
      line = "777:root:root:0:0:symbolic link:/etc/mtab"
      expect(subject.parse_stat_line(line)).to eq(
        [
          "/etc/mtab",
          {
            mode:  "777",
            user:  "root",
            group: "root",
            type:  "link"
          }
        ]
      )
    end
  end

  describe "#get_link_target" do
    it "returns the link target" do
      expect(system).to receive(:run_command).and_return("/etc/foo\n")

      expect(subject.get_link_target("/foo")).to eq("/etc/foo")
    end
  end
end
