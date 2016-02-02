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

require_relative "../spec_helper"

describe "unmanaged_files model" do
  let(:scope) {
    json = create_test_description_json(scopes: ["unmanaged_files"])
    UnmanagedFilesScope.from_json(JSON.parse(json)["unmanaged_files"])
  }

  it_behaves_like "Scope"
  it_behaves_like "FileScope"

  specify { expect(scope).to be_a(UnmanagedFilesScope) }
  specify { expect(scope.first).to be_a(UnmanagedFile) }

  describe UnmanagedFilesScope do
    describe "#length" do
      it "returns the number of files" do
        expect(scope.length).to eq(3)
      end
    end

    describe "#compare_with" do
      it "shows a warning when comparing unextracted with extracted files" do
        scope_a = UnmanagedFilesScope.new([], extracted: false)
        scope_b = UnmanagedFilesScope.new([], extracted: true)
        expect(Machinery::Ui).to receive(:warn)

        scope_a.compare_with(scope_b)
      end

      it "doesn't show a warning when comparing extracted with extracted files" do
        scope_a = UnmanagedFilesScope.new([], extracted: true)
        scope_b = UnmanagedFilesScope.new([], extracted: true)
        expect(Machinery::Ui).to_not receive(:warn)

        scope_a.compare_with(scope_b)
      end
    end
  end

  describe UnmanagedFilesScope do
    describe "#compare_with" do
      it "only compares common properties" do
        scope = UnmanagedFilesScope.new([
          UnmanagedFile.new(
            name: "/foo",
            b:    2
          )
        ])
        scope_equal = UnmanagedFilesScope.new([
          UnmanagedFile.new(
            name: "/foo",
            b:    2,
            c:    3
          )
        ])
        scope_changed = UnmanagedFilesScope.new([
          UnmanagedFile.new(
            name: "/foo",
            b:    3
          )
        ])
        scope_different = UnmanagedFilesScope.new([
          UnmanagedFile.new(
            name: "/bar",
            b:    2
          )
        ])

        expect(scope.compare_with(scope_equal)).to eq([nil, nil, nil, scope])
        expect(scope.compare_with(scope_different)).to eq([scope, scope_different, nil, nil])
        expect(scope.compare_with(scope_changed)).to eq([
          nil,
          nil,
          [
            [
              UnmanagedFile.new(
                name: "/foo",
                b:    2
              ),
              UnmanagedFile.new(
                name: "/foo",
                b:    3
              )
            ]
          ],
          nil])
      end
    end
  end
end
