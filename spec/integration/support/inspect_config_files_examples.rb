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
    it "extracts list of config files" do
      measure("Inspect system") do
        @machinery.run_command(
          "#{machinery_command} inspect #{@subject_system.ip} " \
            "#{inspect_options if defined?(inspect_options)} " \
            "--scope=config-files --extract-files",
          as: "vagrant"
        )
      end

      actual_files_list = @machinery.run_command(
        "#{machinery_command} show #{@subject_system.ip} --scope=config-files",
        as: "vagrant", stdout: :capture
      )

      expected_files_list = File.read("spec/data/config_files/#{base}")

      expect(actual_files_list).to match_machinery_show_scope(expected_files_list)
    end

    it "extracts files from system" do
      actual_config_files = nil
      measure("Gather information about extracted files") do
        actual_config_files = @machinery.run_command(
          "cd #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/config_files/; find -type f",
          as: "vagrant", stdout: :capture
        ).split("\n")
      end

      expected_config_files = []
      expected_files_list = File.read("spec/data/config_files/#{base}")
      expected_files_list.split("\n").each do |e|
        if e.start_with?("  * ") && !e.end_with?("deleted)")
          expected_config_files << ".#{e.split[1]}"
        end
      end
      expect(actual_config_files).to match_array(expected_config_files)

      # test file content
      actual_content = @machinery.run_command(
        "grep config_files_integration_test #{machinery_config[:machinery_dir]}/#{@subject_system.ip}/config_files/etc/crontab",
        as: "vagrant", stdout: :capture
      )
      expect(actual_content).to eq(expected_content)
    end
  end
end
