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

describe ChangedManagedFilesInspector do
  let(:rpm_result) { File.read("spec/data/changed_managed_files/rpm_result") }
  let(:stat_result) { File.read("spec/data/changed_managed_files/stat_result") }
  let(:system) { double }
  let(:description) {
    SystemDescription.new("foo", SystemDescriptionStore.new)
  }
  let(:filter) { nil }
  subject {
    inspector = ChangedManagedFilesInspector.new(system, description)

    allow(system).to receive(:check_requirement).at_least(:once)
    allow(system).to receive(:run_script) do |*script, options|
      expect(script.first).to eq("changed_files.sh")
      options[:stdout].puts rpm_result
    end
    allow(system).to receive(:run_command).with("stat", "--printf",
      "%a:%U:%G:%u:%g:%F:%n\\n", "/etc/iscsi/iscsid.conf",
      "/etc/apache2/de:fault server.conf", "/etc/apache2/listen.conf",
      "/usr/share/man/man1/time.1.gz", "/usr/bin/crontab", anything()).and_return(stat_result)
    allow(system).to receive(:run_command).with("find", "/usr/bin/crontab", any_args).
      and_return("/etc/foo")

    inspector
  }

  describe "#inspect" do
    silence_machinery_output

    context "with filters" do
      it "filters out the matching elements" do
        filter = Filter.new("/changed_managed_files/files/name=/usr/*")
        subject.inspect(filter)
        expect(description["changed_managed_files"].files.map(&:name)).
          to_not include("/usr/share/man/man1/time.1.gz")

        subject.inspect(nil)
        expect(description["changed_managed_files"].files.map(&:name)).
          to include("/usr/share/man/man1/time.1.gz")
      end
    end

    context "without filters" do
      before(:each) do
        subject.inspect(filter)
      end

      it "returns a list of all changed files" do
        expected_result = ChangedManagedFilesScope.new(
          extracted: false,
          files: ChangedManagedFileList.new([
            ChangedManagedFile.new(
              name: "/etc/apache2/de:fault server.conf",
              package_name: "hwinfo",
              package_version: "15.50",
              status: "changed",
              changes: ["size", "md5", "time"],
              user: "wwwrun",
              group: "wwwrun",
              mode: "400",
              type: "file"
            ),
            ChangedManagedFile.new(
              name: "/etc/apache2/listen.conf",
              package_name: "hwinfo",
              package_version: "15.50",
              status: "changed",
              changes: ["md5", "time"],
              user: "root",
              group: "root",
              mode: "644",
              type: "file"
            ),
            ChangedManagedFile.new(
              name: "/etc/iscsi/iscsid.conf",
              package_name: "zypper",
              package_version: "1.6.311",
              status: "changed",
              changes: ["size", "mode", "md5", "user", "group", "time"],
              user: "root",
              group: "root",
              mode: "6644",
              type: "file"
            ),
            ChangedManagedFile.new(
              name: "/opt/kde3/lib64/kde3/plugins/styles/plastik.la",
              package_name: "kdelibs3-default-style",
              package_version: "3.5.10",
              status: "changed",
              changes: ["deleted"]
            ),
            ChangedManagedFile.new(
              name: "/usr/bin/crontab",
              package_name: "cronie",
              package_version: "1.4.8",
              status: "changed",
              changes: ["link_path", "group"],
              user: "root",
              group: "root",
              mode: "755",
              type: "link",
              target: "/etc/foo"
            ),
            ChangedManagedFile.new(
              name: "/usr/share/man/man1/time.1.gz",
              package_name: "hwinfo",
              package_version: "15.50",
              status: "changed",
              changes: ["replaced"],
              user: "wwwrun",
              group: "wwwrun",
              mode: "400",
              type: "file"
            )
          ])
        )
        expect(description["changed_managed_files"]).to eq(expected_result)
      end

      it "returns schema compliant data" do
        expect {
          JsonValidator.new(description.to_hash).validate
        }.to_not raise_error
      end

      it "returns sorted data" do
        names = description["changed_managed_files"].files.map(&:name)

        expect(names).to eq(names.sort)
      end
    end
  end
end
