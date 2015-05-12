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
  let(:file) {
    Machinery::SystemFile.new(
      name: "/etc/ImageVersion",
      type: "file",
      user: "root",
      group: "root",
      size: 25,
      mode: "644"
    )
  }
  let(:link) {
    Machinery::SystemFile.new(
      name: "/etc/alternatives/awk",
      type: "link",
      user: "root",
      group: "root"
    )
  }
  let(:dir) {
    Machinery::SystemFile.new(
      name: "/etc/YaST2/licenses/",
      type: "dir",
      user: "root",
      group: "root",
      size: 101789,
      mode: "755",
      files: 17
    )
  }
  let(:remote_dir) {
    Machinery::SystemFile.new(
      name: "/remote-dir/",
      type: "remote_dir"
    )
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

  describe "#utils" do
    specify { expect(file.utils).to be_a(Machinery::SystemFileUtils) }

    it "initializes the Utils class properly" do
      expect(file.utils.file).to eq(file)
    end
  end
end
