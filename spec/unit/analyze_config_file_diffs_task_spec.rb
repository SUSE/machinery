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

describe AnalyzeConfigFileDiffsTask do
  let(:store) { SystemDescriptionStore.new }
  let(:description) {
    create_test_description(json: <<-EOF, store: store)
      {
        "repositories": [
          {
            "alias": "repo-debug",
            "name": "openSUSE-13.1-Debug",
            "type": null,
            "url": "http://download.opensuse.org/debug/distribution/13.1/repo/oss/",
            "enabled": false,
            "autorefresh": true,
            "gpgcheck": true,
            "priority": 98
          },
          {
            "alias": "dvd_entry_alias",
            "name": "dvd_entry",
            "type": "yast2",
            "url": "dvd:///?devices=/dev/disk/by-id/ata-Optiarc_DVD+_-RW_AD-7200S,/dev/sr0",
            "enabled": true,
            "autorefresh": false,
            "gpgcheck": true,
            "priority": 2
          }
        ], "config_files": {
          "extracted": true,
          "files": [
            {
              "name": "/etc/pam.d/login",
              "package_name": "login",
              "package_version": "3.41",
              "status": "changed",
              "changes": [
                "md5"
              ]
            },
            {
              "name": "/etc/modprobe.d/unsupported-modules",
              "package_name": "aaa_base",
              "package_version": "3.11.1",
              "status": "changed",
              "changes": [
                "md5"
              ]
            },
            {
              "name": "/etc/inittab",
              "package_name": "aaa_base",
              "package_version": "3.11.1",
              "status": "changed",
              "changes": [
                "md5"
              ]
            },
            {
              "name": "/etc/mode_changed_only",
              "package_name": "mode_changed_only",
              "package_version": "1",
              "status": "changed",
              "changes": [
                "mode"
              ]
            }
          ]
        }
      }
    EOF
  }
  subject {
    AnalyzeConfigFileDiffsTask.new
  }

  before(:each) do
    allow(store).to receive(:file_store).and_return("/foo")
    allow_any_instance_of(Zypper).to receive(:add_repo)
    allow_any_instance_of(Zypper).to receive(:remove_repo)
    allow_any_instance_of(Zypper).to receive(:refresh)
  end

  describe "#analyze" do
    include FakeFS::SpecHelpers
    silence_machinery_output

    it "analyzes all files with changes" do
      expect_any_instance_of(Zypper).to receive(:download_package).
        with("aaa_base-3.11.1").and_return("/some/path/aaa_base")
      expect_any_instance_of(Zypper).to receive(:download_package).
        with("login-3.41").and_return("/some/path/login")
      expect(Rpm).to receive(:new).with("/some/path/aaa_base").
        and_return(double(diff: "some aaa_base diff")).twice
      expect(Rpm).to receive(:new).with("/some/path/login").
        and_return(double(diff: "some login diff"))

      subject.analyze(description)
      expect(Dir.glob("/foo/**/*.diff").size).to eq(3)
      expect(File.read("/foo/etc/pam.d/login.diff")).to eq("some login diff")
    end

    it "skips packages which couldn't be downloaded" do
      expect_any_instance_of(Zypper).to receive(:download_package).
        with("aaa_base-3.11.1").and_return(nil)
      expect_any_instance_of(Zypper).to receive(:download_package).
        with("login-3.41").and_return("")
      expect(Machinery::Ui).to receive(:warn).twice
      expect(subject).to_not receive(:generate_diff)

      subject.analyze(description)
    end

    it "raises an error when the description is missing information" do
      task = AnalyzeConfigFileDiffsTask.new
      expect {
        task.analyze(SystemDescription.new("foo",
          SystemDescriptionMemoryStore.new))
      }.to raise_error(Machinery::Errors::SystemDescriptionError)
    end
  end

  describe "#inspection_list" do
    it "groups files by package" do
      expected_group = Package.new(
        "name"    => "aaa_base",
        "version" => "3.11.1",
        "files"   => ["/etc/modprobe.d/unsupported-modules", "/etc/inittab"]
      )

      expect(subject.send(:files_by_package, description)).to include(expected_group)
    end

    it "ignores files where the md5sum did not change" do
      match = subject.send(:files_by_package, description).find {
        |e| e["package_name"] == "mode_changed_only"
      }

      expect(match).to be_nil
    end
  end
end
