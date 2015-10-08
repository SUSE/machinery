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

shared_examples "inspect-container simple scope" do |scope, container|
  describe "--scope=#{scope}" do
    it "inspects #{scope}" do
      measure("Inspect #{scope}") do
        expect(
          @machinery.run_command(
            "#{machinery_command} inspect-container -x machinerytool/#{container} " \
              "--scope=#{scope} --name=test",
            as: "vagrant"
          )
        ).to succeed
      end

      expected = File.read("spec/data/docker/#{scope}/#{container}")
      show_command = @machinery.run_command(
        "#{machinery_command} show test --scope=#{scope}",
        as: "vagrant"
      )
      expect(show_command).to succeed
      expect(show_command.stdout).to match_machinery_show_scope(expected)
    end
  end
end

[
  "packages",
  "patterns",
  "repositories",
  "services",
  "os",
  "users",
  "groups"
].each do |scope|
  shared_examples "inspect-container #{scope}" do |container|
    include_examples("inspect-container simple scope", scope, container)
  end
end

shared_examples "inspect-container" do |container|
  describe "inspect-container #{container}" do
    let(:inspect_options) {
      "--remote-user=#{username}" if username != "root"
    }

    [
      "packages",
      "patterns",
      "repositories",
      "services",
      "os",
      "users",
      "groups",
      "config-files",
      "changed-managed-files"
    ].each do |scope|
      include_examples("inspect-container simple scope", scope, container)
    end

    context "--scope=config-files" do
      it "extracts the files" do
        ls_command = @machinery.run_command(
          "ls #{machinery_config[:machinery_dir]}/test/config_files/etc/",
          as: "vagrant"
        )

        expect(ls_command).to succeed
        expect(ls_command.stdout.chomp).to eq("securetty")
      end
    end

    context "--scope=unmanaged-files" do
      it "inspects unmanaged-files" do
        measure("Inspect unmanaged-files") do
          expect(
            @machinery.run_command(
              "#{machinery_command} inspect-container -x machinerytool/#{container} " \
              "--scope=unmanaged-files --skip-files=/etc/resolv.conf --name=test",
              as: "vagrant"
            )
          ).to succeed
        end

        expected = File.read("spec/data/docker/unmanaged-files/#{container}")
        show_command = @machinery.run_command(
          "#{machinery_command} show test --scope=unmanaged-files",
          as: "vagrant"
        )
        expect(show_command).to succeed
        expect(show_command.stdout).to match_machinery_show_scope(expected)
      end

      it "extracts the files" do
        expected = File.read("spec/data/docker/unmanaged-files/#{container}_files_tgz_content")
        files_content_command = @machinery.run_command(
          "tar -tf #{machinery_config[:machinery_dir]}/test/unmanaged_files/files.tgz",
          as: "vagrant"
        )

        expect(files_content_command).to succeed
        expect(files_content_command.stdout).to eq(expected)
      end

      it "extracts the trees" do
        expected = File.read("spec/data/docker/unmanaged-files/#{container}_etc_lxc_tgz_content")
        tree_content_command = @machinery.run_command(
          "tar -tf #{machinery_config[:machinery_dir]}/test/unmanaged_files/trees/etc/lxc.tgz",
          as: "vagrant"
        )

        expect(tree_content_command).to succeed
        expect(tree_content_command.stdout).to eq(expected)
      end
    end
  end
end
