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

describe Machinery::SystemFileUtils do
  initialize_system_description_factory_store

  class SimpleScope < Machinery::Object
    include Machinery::Scope
  end

  let(:scope_file_store) {
    store = ScopeFileStore.new(given_directory, "unmanaged_files")
    store.create
    store
  }
  let(:scope) {
    Machinery::Scope.initialize_scope("simple", {}, scope_file_store)
  }
  let(:file) {
    file = Machinery::SystemFile.new(
      name: "/etc/ImageVersion",
      type: "file",
      user: "root",
      group: "root",
      size: 25,
      mode: "644"
    )
    file.scope = scope
    file
  }
  let(:link) {
    link = Machinery::SystemFile.new(
      name: "/etc/alternatives/awk",
      type: "link",
      user: "root",
      group: "root"
    )
    link.scope = scope
    link
  }
  let(:dir) {
    dir = Machinery::SystemFile.new(
      name: "/etc/YaST2/licenses/",
      type: "dir",
      user: "root",
      group: "root",
      size: 101789,
      mode: "755",
      files: 17
    )
    dir.scope = scope
    dir
  }
  subject { Machinery::SystemFileUtils }

  describe ".tarball_path" do
    it "returns the path to the tarball for directories" do
      expected = File.join(scope_file_store.path, "trees/etc/YaST2/licenses.tgz")
      expect(subject.tarball_path(dir)).to eq(expected)
    end

    it "returns the file.tgz for files and links" do
      expected = File.join(scope_file_store.path, "files.tgz")
      expect(subject.tarball_path(file)).to eq(expected)
      expect(subject.tarball_path(link)).to eq(expected)
    end
  end

  describe ".write_tarball" do
    context "when handling files" do
      it "fails" do
        expect {
          subject.write_tarball(file, "/tmp")
        }.to raise_error(Machinery::Errors::FileUtilsError)
      end
    end

    context "when handling links" do
      it "fails" do
        expect {
          subject.write_tarball(link, "/tmp")
        }.to raise_error(Machinery::Errors::FileUtilsError)
      end
    end

    context "when handling directories" do
      it "copies the directory tarball to the target location" do
        FileUtils.mkdir_p(File.join(scope_file_store.path, "trees", "etc", "YaST2"))
        FileUtils.touch(File.join(scope_file_store.path, "trees", "etc", "YaST2", "licenses.tgz"))

        target = given_directory
        expected_tarball = File.join(target, "etc", "YaST2", "licenses.tgz")

        subject.write_tarball(dir, target)
        expect(File.exists?(expected_tarball)).to be(true)
      end
    end
  end
end
