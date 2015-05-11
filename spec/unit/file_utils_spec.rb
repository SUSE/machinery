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

describe Machinery::FileUtils do
  include GivenFilesystemSpecHelpers
  use_given_filesystem

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
  subject(:file_utils) { Machinery::FileUtils.new(file) }
  subject(:link_utils) { Machinery::FileUtils.new(link) }
  subject(:dir_utils) { Machinery::FileUtils.new(dir) }

  describe "#write_tarball" do
    context "when handling files" do
      it "fails" do
        expect {
          file_utils.write_tarball("/tmp")
        }.to raise_error(Machinery::Errors::FileUtilsError)
      end
    end

    context "when handling links" do
      it "fails" do
        expect {
          link_utils.write_tarball("/tmp")
        }.to raise_error(Machinery::Errors::FileUtilsError)
      end
    end

    context "when handling directories" do
      it "copies the directory tarball to the target location" do
        FileUtils.mkdir_p(File.join(scope_file_store.base_path, "etc", "YaST2"))
        FileUtils.touch(File.join(scope_file_store.base_path, "etc", "YaST2", "licenses.tgz"))

        target = given_directory
        expected_tarball = File.join(target, "etc", "YaST2", "licenses.tgz")

        dir_utils.write_tarball(target)
        expect(File.exists?(expected_tarball)).to be(true)
      end
    end
  end
end
