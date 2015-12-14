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

shared_examples "inspect config files" do |base|
  expected_content = "-*/15 * * * *   root  echo config_files_integration_test &> /dev/null\n"

  describe "--scope=config-files" do
    it "extracts list of config files and shows progress" do
      measure("Inspect system") do
        inspect_command = @machinery.run_command(
          "FORCE_MACHINERY_PROGRESS_OUTPUT=true #{machinery_command} inspect " \
            "#{@subject_system.ip} #{inspect_options if defined?(inspect_options)} " \
            "--scope=config-files --extract-files",
          as: "vagrant"
        )
        if base == "ubuntu_1404"
          expect(inspect_command).to succeed.with_stderr.
            and include_stderr("Relevant changes might not be caught")
        else
          expect(inspect_command).to succeed
        end

        @machinery_output = inspect_command.stdout
      end

      show_command = @machinery.run_command(
        "#{machinery_command} show #{@subject_system.ip} --scope=config-files",
        as: "vagrant"
      )
      expect(show_command).to succeed

      expected_files_list = File.read("spec/data/config_files/#{base}")
      expect(show_command.stdout).to match_machinery_show_scope(expected_files_list)

      expected = <<EOF
Inspecting 0.0.0.0 for config-files...
Inspecting config-files...
 -> Found 0 config files...\r\033\[K -> Found 0 config files...\r\033\[K -> Extracted 0 changed configuration files.
EOF
      expect(normalize_inspect_output(@machinery_output)).to start_with(expected)
    end

    it "extracts files from system" do
      description_json = @machinery.run_command(
        "cat  #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/manifest.json",
        as: machinery_config[:owner]
      ).stdout
      description = create_test_description(json: description_json)

      actual_config_files = nil
      measure("Gather information about extracted files") do
        actual_config_files = @machinery.run_command(
          "cd #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/config_files/; find -type f",
          as: "vagrant"
        ).stdout.split("\n").map { |file_name| # Remove trailing dots returned by find
          file_name.sub(/^\./, "")
        }
      end

      expected_config_files = description.config_files.select(&:file?).map(&:name)
      expect(actual_config_files).to match_array(expected_config_files)

      # test file content
      expect(
        @machinery.run_command(
          "grep config_files_integration_test #{machinery_config[:machinery_dir]}/" \
          "#{@subject_system.ip}/config_files/etc/crontab",
          as: "vagrant"
        )
      ).to succeed.and have_stdout(expected_content)
    end
  end
end
