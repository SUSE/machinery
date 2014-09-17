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

describe ChangedManagedFilesInspector do
  let(:rpm_result) { File.read("spec/data/changed_managed_files/rpm_result") }
  let(:stat_result) { File.read("spec/data/changed_managed_files/stat_result") }
  let(:system) { double }
  let(:description) {
    SystemDescription.new("foo", {}, SystemDescriptionStore.new)
  }
  subject {
    inspector = ChangedManagedFilesInspector.new

    allow(system).to receive(:run_script).with("changed_managed_files.sh", anything()).and_return(rpm_result)
    allow(system).to receive(:run_command).with("stat", "--printf",
      "%a:%U:%G:%u:%g:%n\\n", "/etc/iscsi/iscsid.conf",
      "/etc/apache2/de:fault server.conf", "/etc/apache2/listen.conf",
      "/usr/share/man/man1/time.1.gz", anything()).and_return(stat_result)

    inspector
  }

  describe "#inspect" do
    it "returns a list of all changed files" do
      expected_result = ChangedManagedFilesScope.new(
        extracted: false,
        files: ChangedManagedFileList.new([
          ChangedManagedFile.new(
              name: "/etc/apache2/de:fault server.conf",
              package_name: "hwinfo",
              package_version: "15.50",
              status: "changed",
              changes: ["md5"],
              user: "wwwrun",
              group: "wwwrun",
              mode: "400",
          ),
          ChangedManagedFile.new(
              name: "/etc/apache2/listen.conf",
              package_name: "hwinfo",
              package_version: "15.50",
              status: "changed",
              changes: ["md5"]
          ),
          ChangedManagedFile.new(
              name: "/etc/iscsi/iscsid.conf",
              package_name: "zypper",
              package_version: "1.6.311",
              status: "changed",
              changes: ["mode", "md5", "user", "group"],
              user: "root",
              group: "root",
              mode: "644",
          ),
          ChangedManagedFile.new(
              name: "/opt/kde3/lib64/kde3/plugins/styles/plastik.la",
              package_name: "kdelibs3-default-style",
              package_version: "3.5.10",
              status: "changed",
              changes: ["deleted"]
          ),
          ChangedManagedFile.new(
              name: "/usr/share/man/man1/time.1.gz",
              package_name: "hwinfo",
              package_version: "15.50",
              status: "changed",
              changes: ["replaced"]
          )
        ])
      )
      subject.inspect(system, description)

      expect(description["changed_managed_files"]).to eq(expected_result)
    end

    it "returns sorted data" do
      subject.inspect(system, description)
      names = description["changed_managed_files"].files.map(&:name)

      expect(names).to eq(names.sort)
    end
  end
end
