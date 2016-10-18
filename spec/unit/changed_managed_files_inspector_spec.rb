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

describe ChangedManagedFilesInspector do
  let(:managed_files_database) { double }

  let(:system) {
    double(
      managed_files_database:                      managed_files_database,
      check_requirement:                 true,
      check_retrieve_files_dependencies: true
    )
  }
  let(:description) {
    Machinery::SystemDescription.new(
      "foo",
      Machinery::SystemDescriptionStore.new
    )
  }
  let(:filter) { nil }

  subject { ChangedManagedFilesInspector.new(system, description) }

  describe "#inspect" do
    before(:each) do
      allow(managed_files_database).to receive(:changed_files).and_return(
        [
          RpmDatabase::ChangedFile.new(
            "c",
            name:            "/etc/config",
            status:          "changed",
            changes:         ["md5"],
            package_name:    "zypper",
            package_version: "1.6.311"
          ),
          RpmDatabase::ChangedFile.new(
            "",
            name:            "/etc/file",
            status:          "changed",
            changes:         ["deleted"],
            package_name:    "zypper",
            package_version: "1.6.311"
          ),
          RpmDatabase::ChangedFile.new(
            "",
            name:            "/etc/dir",
            status:          "changed",
            changes:         ["link_path"],
            package_name:    "zypper",
            package_version: "1.6.311"
          ),
          RpmDatabase::ChangedFile.new(
            "",
            name:            "/etc/documentation",
            status:          "changed",
            changes:         ["user"],
            package_name:    "zypper",
            package_version: "1.6.311"
          ),
          RpmDatabase::ChangedFile.new(
            "",
            name:            "/usr/share/man/man1/time.1.gz",
            status:          "changed",
            changes:         ["user"],
            package_name:    "man",
            package_version: "2"
          )
        ]
      )
      allow(managed_files_database).to receive(:get_path_data).and_return(
        "/etc/file" => {
          user:  "root",
          group: "root",
          mode:  "600",
          type:  "file"
        },
        "/etc/documentation" => {
          user:  "root",
          group: "root",
          mode:  "600",
          type:  "file"
        },
        "/etc/dir" => {
          user:  "root",
          group: "root",
          mode:  "600",
          type:  "dir"
        },
        "/usr/share/man/man1/time.1.gz" => {
          user:  "user",
          group: "root",
          mode:  "600",
          type:  "file"
        }
      )
    end

    context "with filters" do
      it "filters out the matching elements" do
        filter = Filter.new("/changed_managed_files/files/name=/usr/*")

        subject.inspect(filter)
        expect(description["changed_managed_files"].map(&:name)).
          to_not include("/usr/share/man/man1/time.1.gz")

        subject.inspect(nil)
        expect(description["changed_managed_files"].map(&:name)).
          to include("/usr/share/man/man1/time.1.gz")
      end
    end

    context "without filters" do
      before(:each) do
        subject.inspect(filter)
      end

      it "returns a list of all changed files" do
        expected_result = [
          "/etc/file",
          "/etc/dir",
          "/etc/documentation",
          "/usr/share/man/man1/time.1.gz"
        ]
        expect(description["changed_managed_files"].map(&:name)).
          to match_array(expected_result)
      end

      it "returns schema compliant data" do
        expect {
          JsonValidator.new(description.to_hash).validate
        }.to_not raise_error
      end

      it "returns sorted data" do
        names = description["changed_managed_files"].map(&:name)

        expect(names).to eq(names.sort)
      end
    end
  end
end
