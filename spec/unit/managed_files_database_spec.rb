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

require_relative "spec_helper"

describe Machinery::ManagedFilesDatabase do
  describe Machinery::ManagedFilesDatabase::ChangedFile do
    describe "config_file?" do
      it "returns true for configuration files" do
        file = Machinery::ManagedFilesDatabase::ChangedFile.new(
          "c",
          name:    "/etc/foo",
          status:  "changed",
          changes: ["md5"]
        )
        expect(file.config_file?).to be(true)
      end

      it "returns false for non-configuration files" do
        file = Machinery::ManagedFilesDatabase::ChangedFile.new(
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

  let(:system) { Machinery::LocalSystem.new }
  let(:changed_files_sh_result) {
    File.read(File.join(Machinery::ROOT,
      "spec/data/rpm_managed_files_database/changed_files_sh_result"))
  }
  subject { Machinery::ManagedFilesDatabase.new(system) }

  describe "#changed_files" do
    before(:each) do
      allow(subject).to receive(:check_requirements)
      allow(subject).to receive(:managed_files_list).and_return(changed_files_sh_result)
      allow(subject).to receive(:package_for_file_path).and_return(["zypper", "1.6.311"])
      allow(system).to receive(:run_command).with("stat", any_args).and_return(
        File.read(File.join(Machinery::ROOT, "spec/data/rpm_managed_files_database/stat_result"))
      )
      allow(system).to receive(:run_command).with("find", any_args).and_return(
        "/link_target"
      )
    end

    it "returns the list of files" do
      expected = Machinery::ManagedFilesDatabase::ChangedFile.new(
        "",
        name:            "/etc/iscsi/iscsid.conf",
        status:          "changed",
        changes:         ["size", "mode", "md5", "user", "group", "time"],
        package_name:    "zypper",
        package_version: "1.6.311",
        user: "root",
        group: "root",
        mode: "6644",
        type: "file"
      )

      expect(subject.changed_files.first).to eq(expected)
      expect(subject.changed_files.length).to eq(7)
    end

    it "merges lines that refer to the same file" do
      expect(subject).to receive(:managed_files_list).and_return(<<EOF
missing     /lib/modules/3.16.7-29-desktop/updates/vboxpci.ko (replaced)
missing     /lib/modules/3.16.7-29-desktop/updates/vboxpci.ko
EOF
      )

      files = subject.changed_files
      expect(files.count).to eq(1)
      expect(files.first.changes).to match_array(["deleted", "replaced"])
    end
  end

  describe "parse_changes_line" do
    capture_machinery_output

    it "parses an md5 change" do
      line = "..5......  c /etc/pulse/client.conf"
      file, changes, flag = subject.parse_changes_line(line)
      expect(file).to eq("/etc/pulse/client.conf")
      expect(changes).to match_array(["md5"])
      expect(flag).to eq("c")
    end

    it "parses all changes" do
      line = "SM5DLUGTP  c /etc/pulse/client.conf"
      file, changes, flag = subject.parse_changes_line(line)
      expect(file).to eq("/etc/pulse/client.conf")
      expect(changes).to match_array([
        "size", "mode", "md5", "device_number", "link_path", "user", "group", "time", "capabilities"
      ])
      expect(flag).to eq("c")
    end

    it "parses all changes for sles11sp3" do
      line = "SM5DLUGT  c /etc/pulse/client.conf"
      file, changes, flag = subject.parse_changes_line(line)
      expect(file).to eq("/etc/pulse/client.conf")
      expect(changes).to match_array(
        ["size", "mode", "md5", "device_number", "link_path", "user", "group", "time"]
      )
      expect(flag).to eq("c")
    end

    it "parses an unknown change" do
      line = "........S  c /etc/pulse/client.conf"
      file, changes, flag = subject.parse_changes_line(line)
      expect(file).to eq("/etc/pulse/client.conf")
      expect(changes).to match_array(["other_rpm_changes"])
      expect(flag).to eq("c")
    end

    it "it adds other_rpm_changes in case of an unknown rpm change tag" do
      line = "S.......X  c /etc/pulse/client.conf"
      file, changes, flag = subject.parse_changes_line(line)
      expect(file).to eq("/etc/pulse/client.conf")
      expect(changes).to match_array(["size", "other_rpm_changes"])
      expect(flag).to eq("c")
    end

    it "it adds other_rpm_changes in case of an unexpected new/additional rpm tag" do
      line = "S........N  c /etc/pulse/client.conf"
      file, changes, flag = subject.parse_changes_line(line)
      expect(file).to eq("/etc/pulse/client.conf")
      expect(changes).to match_array(["size", "other_rpm_changes"])
      expect(flag).to eq("c")
    end

    it "shows a warning when an rpm test could not be performed but still adds known tags" do
      line = "S.?......  c /etc/pulse/client.conf"
      _, changes = subject.parse_changes_line(line)
      expect(changes).to match_array(["size"])
      expect(captured_machinery_output).to include("Warning: Could not perform all tests on "\
      "rpm changes for file '/etc/pulse/client.conf'.")
    end

    it "logs the warning when an rpm test could not be performed" do
      line = "..?......  c /etc/pulse/client.conf"
      expect(Machinery.logger).to receive(:warn).with("Could not perform all tests on "\
      "rpm changes for file '/etc/pulse/client.conf'.")
      subject.parse_changes_line(line)
    end

    it "treats the replaced flag properly" do
      [
        ".........  c /etc/test.conf (replaced)",
        "missing   c /etc/test.conf (replaced)"
      ].each do |line|
        path, changes = subject.parse_changes_line(line)
        expect(changes).to include("replaced")
        expect(path).to eq("/etc/test.conf")
      end
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

    it "is able to handle empty files" do
      line = "644:root:root:0:0:regular empty file:/etc/postfix/virtual"
      expect(subject.parse_stat_line(line)).to eq(
        [
          "/etc/postfix/virtual",
          {
            mode:  "644",
            user:  "root",
            group: "root",
            type:  "file"
          }
        ]
      )
    end

    it "raises error if the type is unknown" do
      line = "644:root:root:0:0:unknown file type:/etc/somethingweird"
      expect { subject.parse_stat_line(line) }.to raise_error(
        /unknown file type.*\/etc\/somethingweird/
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
