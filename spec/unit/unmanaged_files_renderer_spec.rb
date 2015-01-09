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

describe UnmanagedFilesRenderer do
  let(:description_without_meta) {
    create_test_description(json: <<-EOF)
    {
      "unmanaged_files": {
        "extracted": false,
        "files": [
          {
            "name": "/boot/backup_mbr",
            "type": "file"
          },
          {
            "name": "/boot/message",
            "type": "file"
          }
        ]
      }
    }
    EOF
  }

  let(:description_link) {
    create_test_description(json: <<-EOF)
    {
      "unmanaged_files": {
        "extracted": true,
        "files": [
          {
            "name": "/usr/include/asm",
            "type": "link",
            "user": "root",
            "group": "root"
          }
        ]
      }
    }
    EOF
  }

  let(:description_dir) {
    create_test_description(json: <<-EOF)
    {
      "unmanaged_files": {
        "extracted": true,
        "files": [
          {
            "name": "/etc/iscsi/",
            "type": "dir",
            "user": "root",
            "group": "root",
            "size": 12024,
            "mode": "755",
            "files": 2
          }
        ]
      }
    }
    EOF
  }

  let(:description_file) {
    create_test_description(json: <<-EOF)
    {
      "unmanaged_files": {
        "extracted": true,
        "files": [
          {
            "name": "/etc/modprobe.d/50-ipv6.conf",
            "type": "file",
            "user": "root",
            "group": "root",
            "size": 24,
            "mode": "644"
          }
        ]
      }
    }
    EOF
  }

  let(:empty_description) {
    create_test_description(json: <<-EOF)
    {
      "unmanaged_files": {
        "extracted": true
      }
    }
    EOF
  }

  describe "#render" do
    it "prints a list of files without meta data if non exists" do
      actual_output = UnmanagedFilesRenderer.new.render(description_without_meta)
      expect(actual_output).
        to match(/\/boot\/backup_mbr\ \(file\)\n[^\n]+\/boot\/message\ \(file\)/)
    end

    it "shows the extraction status" do
      actual_output = UnmanagedFilesRenderer.new.render(description_without_meta)
      expect(actual_output).to include("Files extracted: no")
    end

    it "prints a link with meta data" do
      actual_output = UnmanagedFilesRenderer.new.render(description_link)
      expect(actual_output).to include("/usr/include/asm (link)")
      expect(actual_output).to include("User/Group: root:root")
    end

    it "prints a file with meta data" do
      actual_output = UnmanagedFilesRenderer.new.render(description_file)
      expect(actual_output).to include("/etc/modprobe.d/50-ipv6.conf (file)")
      expect(actual_output).to include("Mode: 644")
      expect(actual_output).to include("User/Group: root:root")
      expect(actual_output).to include("Size: 24 B")
    end

    it "prints a dir with meta data" do
      actual_output = UnmanagedFilesRenderer.new.render(description_dir)
      expect(actual_output).to include("/etc/iscsi/ (dir)")
      expect(actual_output).to include("Mode: 755")
      expect(actual_output).to include("User/Group: root:root")
      expect(actual_output).to include("Size: 11.7 KiB")
      expect(actual_output).to include("Files: 2")
    end

    it "does not choke on missing file list" do
      expect {
        UnmanagedFilesRenderer.new.render(empty_description)
      }.to_not raise_error
    end
  end
end
