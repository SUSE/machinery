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

describe System do
  describe ".for" do
    it "returns a LocalSystem when no hostname is given" do
      expect(System.for(nil)).to be_a(LocalSystem)
    end

    it "returns a RemoteSystem when a hostname is given" do
      allow_any_instance_of(RemoteSystem).to receive(:connect)
      remote_system = System.for("somehost", "machinery")

      expect(remote_system).to be_a(RemoteSystem)
      expect(remote_system.host).to eql("somehost")
      expect(remote_system.remote_user).to eq("machinery")
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

    it "excludes excluded files" do
      Dir.mktmpdir("machinery_unittest") do |tmp_dir|
        archive = File.join(tmp_dir, "/archive.tgz")
        test_dir = File.join(tmp_dir, "/test")
        included_file = File.join(test_dir, "included")
        excluded_file_1 = File.join(test_dir, "excluded")
        excluded_file_2 = File.join(test_dir, "excluded?with special:chars")
        FileUtils.mkdir_p(test_dir)
        FileUtils.touch(included_file)
        FileUtils.touch(excluded_file_1)
        FileUtils.touch(excluded_file_2)

        local_system = LocalSystem.new()
        local_system.create_archive(test_dir, archive, [excluded_file_1, excluded_file_2])

        file_list = Tarball.new(archive).list
        # paths in the tarball are relativ to "/", so we have to add it for the comparison
        paths = file_list.map { |f| File.join("/", f[:path]) }
        expect(paths).to match_array([test_dir, included_file])
      end
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

  describe "#has_command" do
    it "returns true if the system has the command" do
      system = LocalSystem.new

      expect(system.has_command?("echo")).to be(true)
    end

    it "returns false if the system hasn't the command" do
      system = LocalSystem.new

      expect(system.has_command?("not_existing_command")).to be(false)
    end
  end
end
