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
    Machinery::UnmanagedFilesScope.from_json(JSON.parse(json)["unmanaged_files"])
  }

  it_behaves_like "Scope"
  it_behaves_like "FileScope"

  specify { expect(scope).to be_a(Machinery::UnmanagedFilesScope) }
  specify { expect(scope.first).to be_a(Machinery::UnmanagedFile) }

  describe Machinery::UnmanagedFilesScope do
    describe "#length" do
      it "returns the number of files" do
        expect(scope.length).to eq(3)
      end
    end

    describe "#compare_with" do
      it "shows a warning when comparing unextracted with extracted files" do
        scope_a = Machinery::UnmanagedFilesScope.new([], extracted: false)
        scope_b = Machinery::UnmanagedFilesScope.new([], extracted: true)
        expect(Machinery::Ui).to receive(:warn)

        scope_a.compare_with(scope_b)
      end

      it "doesn't show a warning when comparing extracted with extracted files" do
        scope_a = Machinery::UnmanagedFilesScope.new([], extracted: true)
        scope_b = Machinery::UnmanagedFilesScope.new([], extracted: true)
        expect(Machinery::Ui).to_not receive(:warn)

        scope_a.compare_with(scope_b)
      end
    end

    describe "check for attributes for rendering" do
      let(:extracted_unmanaged_files) {
        Machinery::UnmanagedFilesScope.new(
          [
            Machinery::UnmanagedFile.new(
              name:    "/foo",
              type:    "file",
              mode:    "777",
              user:    "user",
              group:   "group",
              size:    1,
              files:   2,
              dirs:    3
            )
          ]
        )
      }
      let(:unextracted_unmanaged_files) {
        Machinery::UnmanagedFilesScope.new(
          [
            Machinery::UnmanagedFile.new(
              name: "/foo",
              type:    "file"
            )
          ],
          has_metadata: false
        )
      }
      let(:extracted_unmanaged_files_file_objects) {
        Machinery::UnmanagedFilesScope.new(
          [
            Machinery::UnmanagedFile.new(
              name:    "/foo",
              type:    "file",
              mode:    "777",
              user:    "user",
              group:   "group",
              size:    1,
              file_objects: 4
            )
          ]
        )
      }
      describe "#has_metadata?" do
        it "returns true if the attribute has_metadata is true" do
          object = Machinery::UnmanagedFilesScope.new([], has_metadata: true)
          expect(object.contains_metadata?).to be(true)
        end

        it "returns true if has_metadata is missing but the first element has a user attribute" do
          expect(extracted_unmanaged_files.contains_metadata?).to be(true)
        end

        it "returns false if the attribute has_metadata is false and there is no user attribute" do
          expect(unextracted_unmanaged_files.contains_metadata?).to be(false)
        end
      end

      describe "#has_subdir_counts?" do
        it "returns false if file_objects exist" do
          expect(extracted_unmanaged_files_file_objects.has_subdir_counts?).to be(false)
        end

        it "returns true if subdirectories exist" do
          expect(extracted_unmanaged_files.has_subdir_counts?).to be(true)
        end
      end
    end
  end

  describe Machinery::UnmanagedFilesScope do
    describe "#compare_with" do
      it "only compares common properties" do
        scope = Machinery::UnmanagedFilesScope.new(
          [
            Machinery::UnmanagedFile.new(
              name: "/foo",
              b:    2
            )
          ]
        )
        scope_equal = Machinery::UnmanagedFilesScope.new(
          [
            Machinery::UnmanagedFile.new(
              name: "/foo",
              b:    2,
              c:    3
            )
          ]
        )
        scope_changed = Machinery::UnmanagedFilesScope.new(
          [
            Machinery::UnmanagedFile.new(
              name: "/foo",
              b:    3
            )
          ]
        )
        scope_different = Machinery::UnmanagedFilesScope.new(
          [
            Machinery::UnmanagedFile.new(
              name: "/bar",
              b:    2
            )
          ]
        )

        expect(scope.compare_with(scope_equal)).to eq([nil, nil, nil, scope])
        expect(scope.compare_with(scope_different)).to eq(
          [scope, scope_different, nil, nil]
        )
        expect(scope.compare_with(scope_changed)).to eq(
          [
            nil,
            nil,
            [
              [
                Machinery::UnmanagedFile.new(
                  name: "/foo",
                  b:    2
                ),
                Machinery::UnmanagedFile.new(
                  name: "/foo",
                  b:    3
                )
              ]
            ],
            nil
          ]
        )
      end

      it "keeps the common elements if there are common attributes" do
        scope = Machinery::UnmanagedFilesScope.new(
          [
            Machinery::UnmanagedFile.new(
              name: "/foo",
              b:    2
            )
          ],
          extracted: true
        )
        scope_changed = Machinery::UnmanagedFilesScope.new(
          [
            Machinery::UnmanagedFile.new(
              name: "/foo",
              b:    3
            )
          ],
          extracted: true
        )

        expect(scope.compare_with(scope_changed)).to eq(
          [
            nil,
            nil,
            [
              [
                Machinery::UnmanagedFile.new(
                  name: "/foo",
                  b:    2
                ),
                Machinery::UnmanagedFile.new(
                  name: "/foo",
                  b:    3
                )
              ]
            ],
            Machinery::UnmanagedFilesScope.new([], extracted: true)
          ]
        )
      end
    end
  end
end
