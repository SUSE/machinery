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

shared_examples "inspect unmanaged files" do |base|
  describe "--scope=unmanaged-files" do
    let(:ignore_list) {
      [
        "/var/lib/logrotate.status",
        "/var/spool/cron/lastrun/cron.daily",
        "/var/log/sa",
        "/root/.local",
        "/etc/ssh"
      ]
    }

    def parse_md5sums(output)
      output.split("\n").map { |e| e.split.first }
    end
    test_tarball = File.join(Machinery::ROOT, "../machinery/spec/definitions/vagrant/unmanaged_files.tgz")

    it "extracts list of unmanaged files" do
      measure("Inspect system") do
        @machinery_output = @machinery.run_command(
          "SHOW_PROGRESS_OUTPUT=true #{machinery_command} inspect #{@subject_system.ip} " \
            "#{inspect_options if defined?(inspect_options)} " \
            "--scope=unmanaged-files --extract-files " \
            "--skip-files=#{ignore_list.join(",")}",
          as: "vagrant",
          stdout: :capture
        )
      end

      actual_output = @machinery.run_command(
        "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
        as: "vagrant", stdout: :capture
      )
      # Remove timestamp, so comparison doesn't fail on that.
      # In the future we want to use the Machinery matcher for this, but right
      # now it doesn't generate useable diffs, so doing it manually here for now
      actual = actual_output.split("\n").select { |i| i.start_with?("  * ") }

      expected_output = File.read("spec/data/unmanaged_files/#{base}")
      expected = expected_output.split("\n").select { |i| i.start_with?("  * ") }
      expect(actual).to match_array(expected)

      expected = <<EOF
Inspecting unmanaged-files...
 -> Found 0 files and trees...\r\033\[K -> Found 0 files and trees...\r\033\[K -> Extracted 0 unmanaged files and trees.
EOF
      expect(normalize_inspect_output(@machinery_output)).to include(expected)
    end

    it "extracts meta data of unmanaged files" do
      actual_output = @machinery.run_command(
        "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
        as: "vagrant", stdout: :capture
      )

      # check meta data of a few files
      # complete comparisons aren't possible because of differing log sizes and similar
      file_example = File.read("spec/data/unmanaged_files/output_file.#{base}")
      dir_example  = File.read("spec/data/unmanaged_files/output_dir.#{base}")
      link_example = File.read("spec/data/unmanaged_files/output_link.#{base}")

      expect(actual_output).to include(file_example)
      expect(actual_output).to include(dir_example)
      expect(actual_output).to include(link_example)
    end

    describe "remote file system filtering for unmanaged-files inspector" do
      let(:remote_file_system_tree_path) { "/remote-dir/" }
      let(:remote_file_system_sub_tree_path) { "/mnt/unmanaged/remote-dir/" }

      it "does not extract unmanaged directories which are remote file systems" do
        actual_tarballs = @machinery.run_command(
          "cd #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/unmanaged_files/trees; find -type f",
          as: "vagrant", stdout: :capture
        ).split("\n")

        expect(actual_tarballs).not_to include("./#{remote_file_system_tree_path}.tgz")
      end

      it "lists remote fs directories as 'remote_dir'" do
        actual_output = @machinery.run_command(
          "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
          as: "vagrant", stdout: :capture
        )

        expect(actual_output).to include("* #{remote_file_system_tree_path} (remote_dir)")
      end

      it "also shows remote fs which are mounted in a sub directory of a tree" do
        actual_output = @machinery.run_command(
          "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
          as: "vagrant", stdout: :capture
        )

        expect(actual_output).to include("* #{remote_file_system_sub_tree_path} (remote_dir)")
      end
    end

    it "filters directories which consist temporary or automatically generated files" do
      entries = nil

      measure("Get list of unmanaged-files") do
        entries = @machinery.run_command(
          "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
          as: "vagrant", stdout: :capture
        )
      end

      expect(entries).to_not include("  - /tmp")
      expect(entries).to_not include("  - /var/tmp")
      expect(entries).to_not include("  - /lost+found")
      expect(entries).to_not include("  - /var/run")
      expect(entries).to_not include("  - /var/lib/rpm")
      expect(entries).to_not include("  - /.snapshots")
    end

    it "adheres to user provided filters" do
      entries = @machinery.run_command(
        "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
        as: "vagrant", stdout: :capture
      )

      expect(entries).to_not include("/etc/ssh")
    end

    it "extracts unmanaged files as tarballs" do
      # test extracted files
      actual_tarballs = nil
      actual_filestgz_list = nil
      measure("Gather information about extracted files") do
        actual_tarballs = @machinery.run_command(
          "cd #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/unmanaged_files/trees; find -type f",
          as: "vagrant", stdout: :capture
        ).split("\n")

        actual_filestgz_list = @machinery.run_command(
          "tar -tf #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/unmanaged_files/files.tgz",
          as: "vagrant", stdout: :capture
        ).split("\n")
      end

      expected_tarballs = []
      expected_filestgz_list = []
      expected_output = File.read("spec/data/unmanaged_files/#{base}")
      expected_output.split("\n").each do |line|
        if line.start_with?("  * ")
          file = line.match(/^  \* \/(.*) \(\w+\)$/)[1]
          if line =~ /\(dir\)$/
            expected_tarballs << "./#{file.chomp("/")}.tgz"
          end
          if line =~ /\((file|link)\)$/
            expected_filestgz_list << file
          end
        end
      end

      expect(actual_tarballs).to match_array(expected_tarballs)
      expect(actual_filestgz_list).to match_array(expected_filestgz_list)


      # check content of test tarball
      tmp_dir = Dir.mktmpdir("unmanaged_files", "/tmp")
      expected_output = `cd "#{tmp_dir}"; tar -xf "#{test_tarball}"; md5sum "#{tmp_dir}/srv/test/"*`
      FileUtils.rm_r(tmp_dir)
      expected_md5sums = parse_md5sums(expected_output)

      output = @machinery.run_command(
        "cd /tmp; tar -xf #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/unmanaged_files/trees/srv/test.tgz;" \
          " md5sum /tmp/srv/test/*",
        as: "vagrant", stdout: :capture
      )
      actual_md5sums = parse_md5sums(output)

      expect(actual_md5sums).to match_array(expected_md5sums)
    end

    it "can deal with spaces and quotes in file names" do
      file_output = @machinery.run_command(
        "ls #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/unmanaged_files/trees/opt/test-quote-char/test-dir-name-with-\\'\\ quote-char\\ \\'/unmanaged-dir-with-\\'\\ quote\\ \\'.tgz",
        as: "vagrant", stdout: :capture
      )
      expect(file_output).to include("unmanaged-dir-with-' quote '.tgz")

      show_output = @machinery.run_command(
        "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
        as: "vagrant", stdout: :capture
      )
      expect(show_output).to include("unmanaged-file-with-' quote '")
      expect(show_output).to include("unmanaged-dir-with-' quote '")
    end
  end
end
