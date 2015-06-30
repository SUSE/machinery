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

require_relative "../spec_helper"

describe "unmanaged_files model" do
  let(:scope) {
    json = create_test_description_json(scopes: ["unmanaged_files"])
    UnmanagedFilesScope.from_json(JSON.parse(json)["unmanaged_files"])
  }

  it_behaves_like "Scope"
  it_behaves_like "FileScope"

  specify { expect(scope.files).to be_a(UnmanagedFileList) }
  specify { expect(scope.files.first).to be_a(UnmanagedFile) }

  describe UnmanagedFilesScope do
    describe "#compare_with" do
      it "shows a warning when comparing unextracted with extracted files" do
        scope_a = UnmanagedFilesScope.new(extracted: false, files: UnmanagedFileList.new([]))
        scope_b = UnmanagedFilesScope.new(extracted: true, files: UnmanagedFileList.new([]))
        expect(Machinery::Ui).to receive(:warn)

        scope_a.compare_with(scope_b)
      end

      it "doesn't show a warning when comparing extracted with extracted files" do
        scope_a = UnmanagedFilesScope.new(extracted: true, files: UnmanagedFileList.new([]))
        scope_b = UnmanagedFilesScope.new(extracted: true, files: UnmanagedFileList.new([]))
        expect(Machinery::Ui).to_not receive(:warn)

        scope_a.compare_with(scope_b)
      end
    end
  end

  describe UnmanagedFileList do
    describe "#compare_with" do
      it "only compares common properties" do
        list = UnmanagedFileList.new([
          UnmanagedFile.new(
            a: 1
          )
        ])
        list_equal = UnmanagedFileList.new([
          UnmanagedFile.new(
            a: 1,
            b: 2
          )
        ])
        list_different = UnmanagedFileList.new([
          UnmanagedFile.new(
            a: 2,
            b: 2
          )
        ])

        expect(list.compare_with(list_equal)).to eq([nil, nil, nil, list])
        expect(list.compare_with(list_different)).to eq([list, list_different, nil, nil])
      end
    end
  end
end
