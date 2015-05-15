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
require File.expand_path("../../../helpers/inspector_files", __FILE__)

describe ReferenceTestData do
  describe ".inspect_system" do
    it "inspects a system with given IP-adress" do
      ip_adress = "192.168.121.102"
      expect(Cheetah).to receive(:run).with(
        anything, "inspect", ip_adress, "-n", "referencetestdata", stdout: :capture
      )

      subject.inspect(ip_adress)
    end
  end

  describe ".write_inspector_file" do
    include GivenFilesystemSpecHelpers
    use_given_filesystem

    it "writes machinery show output in the inspector files" do
      inspector_file = given_dummy_file
      destination = "sles12"
      content = "package 0815"

      expect(Cheetah).to receive(:run).and_return(content).at_least(:once)

      expect(subject).to receive(:file_path).and_return(inspector_file).at_least(:once)

      subject.write(destination)
      expect(File.readlines(inspector_file)[0]).to eq(content)
    end
  end

  describe ".file_path" do
    it "returns the whole path of the inspector file" do
      expect(subject.file_path("os", "sles12")).to match(/\/os\/sles12$/)
    end
  end
end
