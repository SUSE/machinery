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

require_relative "integration_spec_helper"

describe "machinery@openSUSE Tumbleweed" do
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
          /\* Main Repository \(OSS\)$/,
          /URI: http:\/\/download\.opensuse\.org\/tumbleweed\/repo\/oss\/$/,
          /Alias: download\.opensuse\.org-oss$/,
          /Refresh: Yes$/,
          /Priority: 99$/,
          /Package Manager: zypp$/
        ],
      "services" =>
        [
          /\* sshd.service: enabled$/,
          /\* rc-local.service: static$/,
          /\* debug-shell.service: disabled$/
        ],
      "os" =>
        [
          /Name: openSUSE Tumbleweed$/,
          /Version: .* \(Tumbleweed\)$/,
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
      "config-files" =>
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

  before(:all) do
    @machinery = start_system(box: "machinery_tumbleweed")
  end

  include_examples "CLI"
  include_examples "kiwi export"
  include_examples "autoyast export"
  include_examples "validate"
  include_examples "upgrade format"
  include_examples "generate html"

  describe "inspect openSUSE Tumbleweed system" do
    before(:all) do
      @subject_system = start_system(box: "opensuse_tumbleweed")
      prepare_machinery_for_host(@machinery, @subject_system.ip, password: "vagrant")
    end

    Inspector.all_scopes.map { |i| i.gsub("_", "-") }.each do |scope|
      describe "--scope=#{scope}" do
        it "inspects #{scope}" do
          measure("Inspect #{scope}") do
            @machinery.run_command(
              "#{machinery_command} inspect #{@subject_system.ip} --extract-files" \
                " --scope=#{scope} --name=test",
              as: "vagrant",
              stdout: :capture
            )
          end

          show_output = @machinery.run_command(
            "#{machinery_command} show test --scope=#{scope}",
            as: "vagrant",
            stdout: :capture
          )
          test_data[scope].each do |regex|
            expect(show_output).to match(regex)
          end
        end
      end
    end
  end
end
