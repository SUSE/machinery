# Copyright (c) 2013-2014 SUSE LLC
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

describe System do
  describe ".for" do
    it "returns a LocalSystem when no hostname is given" do
      expect(System.for(nil)).to be_a(LocalSystem)
    end

    it "returns a RemoteSystem when a hostname is given" do
      allow_any_instance_of(RemoteSystem).to receive(:connect)
      remote_system = System.for("somehost")

      expect(remote_system).to be_a(RemoteSystem)
      expect(remote_system.host).to eql("somehost")
    end
  end

  describe "#create_archive" do
    it "creates an archive on LocalSystem" do
      dir = Dir.mktmpdir("machinery_unittest")
      test_dir = dir + "/test"
      md5_file = dir + "/md5"
      extract_dir = dir + "/extract"
      archive = dir + "/archive.tgz"

      FileUtils.cp_r("spec/data/system/archive_test", test_dir)

      filelist = Dir.glob(test_dir + "/*").join("\0")

      local_system = LocalSystem.new()
      md5sum = local_system.run_command(
        ["find", test_dir, "-type", "f"],
        ["xargs", "md5sum"],
        :stdout => :capture
      )
      File.write(md5_file, md5sum)
      lines = local_system.run_command(
        "find", test_dir,
        :stdout => :capture
      )
      lines=lines.count("\n")

      local_system.create_archive(filelist,archive)

      expect(File.stat(archive).mode.to_s(8)[-3..-1]).to eq("600")
      FileUtils.mkdir(extract_dir)
      local_system.run_command( "tar", "--extract", "--gzip",
        "--directory=" + extract_dir,
        "--file=" + archive
      )
      test_lines = local_system.run_command(
        "find", extract_dir + test_dir,
        :stdout => :capture
      )
      expect(test_lines.count("\n")).to eq(lines)

      md5sum.gsub!(/ \/tmp\//, " " + extract_dir + "/tmp/")
      local_system.run_command("md5sum", "-c", :stdin => md5sum)
      FileUtils.rm_r(dir)
    end
  end

  describe "#run_script" do
    it "reads the script from MACHINERY_ROOT/helpers/ and executes it" do
      begin
        FakeFS.activate!
        stub_const("Machinery::ROOT", "/")
        FileUtils.mkdir("/helpers")
        File.write("/helpers/foo", "ls /foo")

        system = System.new
        expect(system).to receive(:run_command).
          with("bash", "-c", "ls /foo", stdout: :capture)

        system.run_script("foo", stdout: :capture)
      ensure
        FakeFS.deactivate!
      end
    end
  end
end
