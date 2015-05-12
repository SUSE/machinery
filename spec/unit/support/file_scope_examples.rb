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

shared_examples "FileScope" do
  initialize_system_description_factory_store

  let(:file_a) {
    {
      name: "foo"
    }
  }
  let(:file_b) {
    {
      name: "bar"
    }
  }
  let(:file_c) {
    {
      name: "baz"
    }
  }

  describe "#export_files_as_tarballs" do
    it "should copy all tarballs to the destination" do
      description = create_test_description(
        store_on_disk: true,
        extracted_scopes: ["unmanaged_files"]
      )

      target = given_directory
      description.unmanaged_files.export_files_as_tarballs(target)

      expect(File.exists?(File.join(target, "files.tgz"))).to be(true)
      expect(File.exists?(File.join(target, "trees/etc/tarball with spaces.tgz"))).to be(true)
    end
  end

  describe "#compare_with" do
    it "compares for equal objects" do
      a = scope.class.new(
        extracted: true,
        files: [file_a, file_b]
      )
      b = scope.class.new(
        extracted: true,
        files: [file_a, file_b]
      )

      comparison = a.compare_with(b)
      expect(comparison).to eq([nil, nil, a])
    end

    it "works for differing objects" do
      a = scope.class.new(
        extracted: true,
        files: [file_a, file_b]
      )
      b = scope.class.new(
        extracted: false,
        files: [file_c, file_b]
      )

      comparison = a.compare_with(b)
      expect(comparison).to eq([
        scope.class.new(extracted: true, files: [file_a]),
        scope.class.new(extracted: false, files: [file_c]),
        scope.class.new(files: [file_b])
      ])
    end

    it "raises an error when there is an unknown attribute" do
      a = scope.class.new(
        foo: 1
      )
      b = scope.class.new(
        foo: 1
      )

      expect {
        a.compare_with(b)
      }.to raise_error(Machinery::Errors::MachineryError, /attributes.*foo/)
    end
  end
end
