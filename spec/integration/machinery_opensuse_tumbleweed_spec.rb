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

require "net/http"
require_relative "integration_spec_helper"

describe "machinery@Tumbleweed" do
  let(:test_data) {
    {
      "packages" =>
        [
          /\* zypper-\d+\..*\.x86_64 \(openSUSE\)$/,
          /\* ca-certificates-\d.*\.noarch \(openSUSE\)$/
        ],
      "patterns" =>
        [
          /\* base$/
        ],
      "repositories" =>
        [
          /\* Main_Repository$/,
          /URI: http:\/\/download\.opensuse\.org\/tumbleweed\/repo\/oss\/$/,
          /Alias: Main_Repository$/,
          /Enabled: Yes$/,
          /Refresh: Yes$/,
          /Priority: 99$/,
          /Type: yast2$/
        ],
      "services" =>
        [
          /\* sshd.service: enabled$/,
          /\* wickedd-pppd@.service: static$/,
          /\* debug-shell.service: disabled$/
        ],
      "os" =>
        [
          /Name: openSUSE Tumbleweed$/,
          /Version: [0-9]{8}$/,
          /Architecture: x86_64$/
        ],
      "users" =>
        [
          /\* \+ \(N\/A, uid: N\/A, gid: N\/A, shell: \)$/,
          /\* bin \(bin, uid: 1, gid: 1, shell: \/bin\/bash\)$/
        ],
      "groups" =>
        [
          /\* \+ \(gid: N\/A\)$/,
          /\* bin \(gid: 1, users: daemon\)$/
        ],
      "changed-config-files" =>
        [
          /Files extracted: yes$/,
          /\* \/etc\/auto\.master \(autofs-\d+.*, size, md5\)$/
        ],
      "changed-managed-files" =>
        [
          /Files extracted: yes$/,
          /\* \/usr\/share\/info\/sed.info.gz \(size, md5\)$/,
          /\* \/usr\/share\/man\/man1\/sed\.1\.gz \(deleted\)$/
        ],
      "unmanaged-files" =>
        [
          /Files extracted: yes$/,
          /\* \/etc\/magicapp\.conf \(file\)$/,
          /User\/Group: root:root$/,
          /Mode: [0-7]{3}$/,
          /Size: \d+/
        ]
    }
  }

  let(:machinery_config) {
    {
      machinery_dir: "/home/vagrant/.machinery",
      owner: "vagrant",
      group: "vagrant"
    }
  }
  let(:machinery_command) { "machinery" }

  host = machinery_host(metadata[:description])

  before(:all) do
    @machinery = start_system(box: "machinery_#{host}")
  end

  include_examples_for_platform(host)

  describe "inspect openSUSE Tumbleweed system", matrix: "pending" do
    before(:all) do
      @subject_system = start_system(
        box: "opensuse_tumbleweed", username: "machinery", password: "linux"
      )
      prepare_machinery_for_host(
        @machinery, @subject_system.ip, username: "machinery", password: "linux"
      )
    end

    Machinery::Inspector.all_scopes.map { |i| i.tr("_", "-") }.each do |scope|
      describe "--scope=#{scope}" do
        it "inspects #{scope}" do
          measure("Inspect #{scope}") do
            expect(
              @machinery.run_command(
                "#{machinery_command} inspect #{@subject_system.ip} --remote-user=machinery" \
                  " --extract-files --scope=#{scope} --name=test",
                as: "vagrant"
              )
            ).to succeed.with_or_without_stderr
          end

          show_command = @machinery.run_command(
            "#{machinery_command} show test --scope=#{scope}", as: "vagrant"
          )
          expect(show_command).to succeed

          test_data[scope].each do |regex|
            expect(show_command.stdout).to match(regex)
          end
        end
      end
    end

    context "when the use of the stat command is required while running as a remote user" do
      it "runs with privileged permissions" do
        expect(
          @machinery.run_command(
            "#{machinery_command} inspect #{@subject_system.ip} --remote-user=machinery " \
            "--scope=changed-config-files --extract-files --show", as: "vagrant"
          )
        ).to succeed.and include_stdout(
          "* /etc/stat-test/test.conf (test-data-files-1.0, size, md5)"
        )
      end
    end
  end
end
