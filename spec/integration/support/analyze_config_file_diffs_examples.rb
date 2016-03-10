#  Copyright (c) 2013-2016 SUSE LLC
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 3 of the GNU General Public License as
#  published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.
#
#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

shared_examples "analyze config file diffs" do |distribution|
  describe "--operation=config-file-diffs" do
    it "generates diffs for the changed config files" do
      system_description_file = "spec/data/descriptions/jeos/#{distribution}/manifest.json"
      system_description_dir = File.dirname(system_description_file)

      @machinery.inject_directory(
        system_description_dir,
        "/home/vagrant/.machinery/",
        owner: "vagrant",
        group: "users"
      )

      measure("Analyze system description") do
        expect(
          @machinery.run_command(
            "machinery analyze #{distribution} --operation=config-file-diffs",
            as: "vagrant"
          )
        ).to succeed
      end

      show_command = @machinery.run_command(
        "machinery show #{distribution} --scope=changed-config-files --show-diffs",
        as: "vagrant"
      )

      expect(show_command).to succeed
      expect(show_command.stdout).to match_machinery_show_scope(
        File.read("spec/data/analyze_config_file_diffs/#{distribution}"))
    end
  end
end
