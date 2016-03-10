# Copyright (c) 2013-2016 SUSE LLC
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

shared_examples "upgrade format" do
  describe "upgrade-format" do
    it "Upgrades an existing system description" do
      @machinery.inject_directory(
        File.join(Machinery::ROOT, "spec/data/descriptions/format_v1/"),
        "/home/vagrant/.machinery/",
        owner: "vagrant",
        group: "users"
      )

      expect(
        @machinery.run_command("machinery show format_v1", as: "vagrant")
      ).to fail.and include_stderr("needs to be upgraded")

      expect(
        @machinery.run_command("machinery upgrade-format format_v1", as: "vagrant")
      ).to succeed

      show_command = @machinery.run_command(
          "machinery show format_v1 -s unmanaged-files",
          as: "vagrant"
      )
      expect(show_command).to succeed
      expected = File.read(
        File.join(Machinery::ROOT, "spec/data/upgrade-format/format_v1_upgraded")
      )
      expect(show_command.stdout).to match_machinery_show_scope(expected)
    end

    it "Upgrades format v2 to v3" do
      @machinery.inject_directory(
        File.join(Machinery::ROOT, "spec/data/descriptions/format_v2/"),
        "/home/vagrant/.machinery/",
        owner: "vagrant",
        group: "users"
      )

      expect(
        @machinery.run_command("machinery upgrade-format format_v2", as: "vagrant")
      ).to succeed

      show_command = @machinery.run_command(
          "machinery show format_v2 --scope=config-files --show-diffs",
          as: "vagrant"
      )
      expect(show_command).to succeed
      expected = File.read(
        File.join(Machinery::ROOT, "spec/data/upgrade-format/format_v2_upgraded_changed_config_files")
      )
      expect(show_command.stdout).to match_machinery_show_scope(expected)

      show_command = @machinery.run_command(
          "machinery show format_v2 --scope=repositories --show-diffs",
          as: "vagrant"
      )
      expect(show_command).to succeed
      expected = File.read(
        File.join(Machinery::ROOT, "spec/data/upgrade-format/format_v2_upgraded_repositories")
      )
      expect(show_command.stdout).to match_machinery_show_scope(expected)
    end
  end
end
