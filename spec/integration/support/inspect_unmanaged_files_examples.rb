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
        "/etc/ssh",
        "/var/log/mcelog"
      ]
    }

    def parse_md5sums(output)
      output.split("\n").map { |e| e.split.first }
    end
    test_tarball = File.join(Machinery::ROOT, "../machinery/spec/definitions/vagrant/unmanaged_files.tgz")

    it "extracts list of unmanaged files" do
      inspect_command = nil
      measure("Inspect system") do
        inspect_command = @machinery.run_command(
          "FORCE_MACHINERY_PROGRESS_OUTPUT=true #{machinery_command} inspect " \
            "#{@subject_system.ip} #{inspect_options if defined?(inspect_options)} " \
            "--scope=unmanaged-files --extract-files " \
            "--skip-files=#{ignore_list.join(",")}",
          as: "vagrant"
        )
        expect(inspect_command).to succeed.with_stderr.and include_stderr("contains invalid UTF-8")
      end

      show_command = @machinery.run_command(
        "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
        as: "vagrant"
      )
      expect(show_command).to succeed

      # Remove timestamp, so comparison doesn't fail on that.
      # In the future we want to use the Machinery matcher for this, but right
      # now it doesn't generate useable diffs, so doing it manually here for now
      actual = show_command.stdout.split("\n").select { |i| i.start_with?("  * ") }

      expected_output = File.read("spec/data/unmanaged_files/#{base}")
      expected = expected_output.split("\n").select { |i| i.start_with?("  * ") }
      expect(actual).to match_array(expected)

      # Note: We normalize numbers in tthe output in order to make the comparison more robust,
      # that's why the architecture string "x86_64" ends up as x0_0
      expected = <<EOF
Inspecting unmanaged-files...
Note: Using traditional inspection because file extraction is not supported by the helper binary.
 -> Found 0 files and trees...\r\033\[K -> Found 0 files and trees...\r\033\[K -> Extracted 0 unmanaged files and trees.
EOF
      expect(normalize_inspect_output(inspect_command.stdout)).to include(expected)
    end

    it "extracts meta data of unmanaged files" do
      # check meta data of a few files
      # complete comparisons aren't possible because of differing log sizes and similar
      file_example = File.read("spec/data/unmanaged_files/output_file.#{base}")
      dir_example  = File.read("spec/data/unmanaged_files/output_dir.#{base}")
      link_example = File.read("spec/data/unmanaged_files/output_link.#{base}")

      expect(
        @machinery.run_command(
          "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
          as: "vagrant"
        )
      ).to succeed.
        and include_stdout(file_example).
        and include_stdout(dir_example).
        and include_stdout(link_example)
    end

    describe "remote file system filtering for unmanaged-files inspector" do
      let(:remote_file_system_tree_path) { "/remote-dir/" }
      let(:remote_file_system_sub_tree_path) { "/mnt/unmanaged/remote-dir/" }

      it "does not extract unmanaged directories which are remote file systems" do
        expect(
          @machinery.run_command(
            "cd #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/unmanaged_files/trees; " \
            "find -type f", as: "vagrant"
          )
        ).to succeed.and not_include_stdout("./#{remote_file_system_tree_path}.tgz")
      end

      it "lists remote fs directories as 'remote_dir'" do
        expect(
          @machinery.run_command(
            "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
            as: "vagrant"
          )
        ).to succeed.and include_stdout("* #{remote_file_system_tree_path} (remote_dir)")
      end

      it "also shows remote fs which are mounted in a sub directory of a tree" do
        expect(
          @machinery.run_command(
            "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
            as: "vagrant"
          )
        ).to succeed.and include_stdout("* #{remote_file_system_sub_tree_path} (remote_dir)")
      end
    end

    it "filters directories which consist temporary or automatically generated files" do
      measure("Get list of unmanaged-files") do
        expect(
          @machinery.run_command(
            "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
            as: "vagrant"
          )
        ).to succeed.
          and not_include_stdout("  - /tmp").
          and not_include_stdout("  - /tmp").
          and not_include_stdout("  - /var/tmp").
          and not_include_stdout("  - /lost+found").
          and not_include_stdout("  - /var/run").
          and not_include_stdout("  - /var/lib/rpm").
          and not_include_stdout("  - /.snapshots")
      end

    end

    it "adheres to user provided filters" do
      expect(
        @machinery.run_command(
          "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
          as: "vagrant"
        )
      ).to succeed.and not_include_stdout("/etc/ssh")
    end

    it "extracts unmanaged files as tarballs" do
      # test extracted files
      tarballs_command = nil
      files_command = nil
      measure("Gather information about extracted files") do
        tarballs_command = @machinery.run_command(
          "cd #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/unmanaged_files/trees; find -type f",
          as: "vagrant"
        )

        files_command = @machinery.run_command(
          "tar -tf #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/unmanaged_files/files.tgz",
          as: "vagrant"
        )
      end

      expect(tarballs_command).to succeed
      expect(files_command).to succeed

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

      expect(tarballs_command.stdout.split("\n")).to match_array(expected_tarballs)
      expect(files_command.stdout.split("\n")).to match_array(expected_filestgz_list)


      # check content of test tarball
      tmp_dir = Dir.mktmpdir("unmanaged_files", "/tmp")
      expected_output = `cd "#{tmp_dir}"; tar -xf "#{test_tarball}"; md5sum "#{tmp_dir}/srv/test/"*`
      FileUtils.rm_r(tmp_dir)
      expected_md5sums = parse_md5sums(expected_output)

      md5_command = @machinery.run_command(
        "cd /tmp; tar -xf #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/unmanaged_files/trees/srv/test.tgz;" \
          " md5sum /tmp/srv/test/*",
        as: "vagrant"
      )
      expect(md5_command).to succeed
      actual_md5sums = parse_md5sums(md5_command.stdout)

      expect(actual_md5sums).to match_array(expected_md5sums)
    end

    it "can deal with spaces and quotes in file names" do
      file_command = @machinery.run_command(
        "ls #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/unmanaged_files/trees/opt/test-quote-char/test-dir-name-with-\\'\\ quote-char\\ \\'/unmanaged-dir-with-\\'\\ quote\\ \\'.tgz",
        as: "vagrant"
      )
      expect(file_command).to succeed.and include_stdout("unmanaged-dir-with-' quote '.tgz")

      show_command = @machinery.run_command(
        "#{machinery_command} show #{@subject_system.ip} --scope=unmanaged-files",
        as: "vagrant"
      )
      expect(show_command).to succeed.and include_stdout("unmanaged-file-with-' quote '").
        and include_stdout("unmanaged-dir-with-' quote '")
    end
  end
end
