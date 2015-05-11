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

describe Machinery::File do
  let(:file) {
    Machinery::File.new(
      name: "/etc/ImageVersion",
      type: "file",
      user: "root",
      group: "root",
      size: 25,
      mode: "644"
    )
  }
  let(:link) {
    Machinery::File.new(
      name: "/etc/alternatives/awk",
      type: "link",
      user: "root",
      group: "root"
    )
  }
  let(:dir) {
    Machinery::File.new(
      name: "/etc/YaST2/licenses/",
      type: "dir",
      user: "root",
      group: "root",
      size: 101789,
      mode: "755",
      files: 17
    )
  }

  describe "#file?" do
    it "returns true when it is a file" do
      expect(file.file?).to be(true)
    end

    it "returns false when its a link" do
      expect(link.file?).to be(false)
    end

    it "returns false when its a directory" do
      expect(dir.file?).to be(false)
    end
  end

  describe "#link?" do
    it "returns true when its a link" do
      expect(link.link?).to be(true)
    end

    it "returns false when it is a file" do
      expect(file.link?).to be(false)
    end

    it "returns false when its a directory" do
      expect(dir.link?).to be(false)
    end
  end

  describe "#directory?" do
    it "returns true when its a directory" do
      expect(dir.directory?).to be(true)
    end

    it "returns false when its a link" do
      expect(link.directory?).to be(false)
    end

    it "returns false when it is a file" do
      expect(file.directory?).to be(false)
    end
  end

  describe "#utils" do
    specify { expect(file.utils).to be_a(Machinery::FileUtils) }

    it "initializes the Utils class properly" do
      expect(file.utils.file).to eq(file)
    end
  end
end
