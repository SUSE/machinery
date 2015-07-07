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

describe Machinery::SystemFile do
  let(:scope) { double(extracted: true) }
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
  let(:deleted_file) {
    file = Machinery::SystemFile.new(
      name: "/usr/share/man/man1/sed.1.gz",
      package_name: "sed",
      package_version: "4.2.2",
      status: "changed",
      changes: [
        "deleted"
      ]
    )
    file.scope = scope
    file
  }
  let(:link) {
    file = Machinery::SystemFile.new(
      name: "/etc/alternatives/awk",
      type: "link",
      user: "root",
      group: "root"
    )
    file.scope = scope
    file
  }
  let(:dir) {
    file = Machinery::SystemFile.new(
      name: "/etc/YaST2/licenses/",
      type: "dir",
      user: "root",
      group: "root",
      size: 101789,
      mode: "755",
      files: 17
    )
    file.scope = scope
    file
  }
  let(:remote_dir) {
    file = Machinery::SystemFile.new(
      name: "/remote-dir/",
      type: "remote_dir"
    )
    file.scope = scope
    file
  }

  context "files only return true for #file?" do
    specify { expect(file.file?).to be(true) }
    specify { expect(file.link?).to be(false) }
    specify { expect(file.directory?).to be(false) }
    specify { expect(file.remote_directory?).to be(false) }
  end

  context "links only return true for #link?" do
    specify { expect(link.link?).to be(true) }
    specify { expect(link.file?).to be(false) }
    specify { expect(link.directory?).to be(false) }
    specify { expect(link.remote_directory?).to be(false) }
  end

  context "directories only return true for #directory?" do
    specify { expect(dir.directory?).to be(true) }
    specify { expect(dir.file?).to be(false) }
    specify { expect(dir.link?).to be(false) }
    specify { expect(dir.remote_directory?).to be(false) }
  end

  context "remote_directories only return true for #remote_directory?" do
    specify { expect(remote_dir.remote_directory?).to be(true) }
    specify { expect(remote_dir.file?).to be(false) }
    specify { expect(remote_dir.link?).to be(false) }
    specify { expect(remote_dir.directory?).to be(false) }
  end

  describe "#deleted?" do
    specify { expect(file.deleted?).to be(false) }
    specify { expect(deleted_file.deleted?).to be(true) }
  end

  describe "#on_disk?" do
    specify { expect(file.on_disk?).to be(true) }
    specify {
      allow(scope).to receive(:extracted).and_return(false)
      expect(file.on_disk?).to be(false)
    }
    specify { expect(deleted_file.on_disk?).to be(false) }
    specify { expect(link.on_disk?).to be(false) }
    specify { expect(dir.on_disk?).to be(false) }
    specify { expect(remote_dir.on_disk?).to be(false) }
  end

  describe "#binary?" do
    it "delegates to scope" do
      result = double
      expect(scope).to receive(:binary?).with(file).and_return(result)

      expect(file.binary?).to eq(result)
    end
  end

  describe "#on_disk?" do
    it "delegates to scope" do
      result = double
      expect(scope).to receive(:file_content).with(file).and_return(result)

      expect(file.content).to eq(result)
    end
  end
end
