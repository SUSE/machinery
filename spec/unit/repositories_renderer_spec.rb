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

describe RepositoriesRenderer do
  let(:system_description) {
    create_test_description(scopes: ["repositories"])
  }

  describe "#content" do
    it "prints a repository list" do
      output = RepositoriesRenderer.new.render(system_description)

      expected_output = <<EOT
  * nodejs
    URI: http://download.opensuse.org/repositories/devel:/languages:/nodejs/openSUSE_13.1/
    Alias: nodejs_alias
    Enabled: Yes
    Refresh: No
    Priority: 1
    Package Manager: zypp

  * openSUSE-13.1-1.7
    URI: cd:///?devices=/dev/disk/by-id/ata-Optiarc_DVD+_-RW_AD-7200S,/dev/sr0
    Alias: openSUSE-13.1-1.7_alias
    Enabled: No
    Refresh: No
    Priority: 2
    Package Manager: zypp

  * repo_without_type
    URI: http://repo-without-type
    Alias: repo_without_type_alias
    Enabled: Yes
    Refresh: No
    Priority: 3
    Package Manager: zypp

  * disabled_repo
    URI: http://disabled-repo
    Alias: disabled_repo_alias
    Enabled: No
    Refresh: No
    Priority: 3
    Package Manager: zypp

  * autorefresh_enabled
    URI: http://autorefreshed-repo
    Alias: autorefresh_enabled_alias
    Enabled: Yes
    Refresh: Yes
    Priority: 2
    Package Manager: zypp

  * dvd_entry
    URI: dvd:///?devices=/dev/disk/by-id/ata-Optiarc_DVD+_-RW_AD-7200S,/dev/sr0
    Alias: dvd_entry_alias
    Enabled: Yes
    Refresh: No
    Priority: 2
    Package Manager: zypp

  * NCC Repository
    URI: https://nu.novell.com/repo/$RCE/SLES11-SP3-Pool/sle-11-x86_64?credentials=NCCcredentials
    Alias: NCCRepo
    Enabled: Yes
    Refresh: Yes
    Priority: 2
    Package Manager: zypp
EOT
      expect(output).to include(expected_output)
    end

    it "prints an apt repository list" do
      output = RepositoriesRenderer.new.render(
        create_test_description(scopes: ["apt_repositories"])
      )

      expected_output = <<EOT
  * URI: http://de.archive.ubuntu.com/ubuntu/
    Distribution: trusty
    Components: main, restricted
    Type: deb
    Package Manager: apt

  * URI: http://de.archive.ubuntu.com/ubuntu/
    Distribution: trusty
    Components: main, restricted
    Type: deb-src
    Package Manager: apt
EOT
      expect(output).to include(expected_output)
    end

    context "when there are no repositories" do
      let(:system_description) { create_test_description(scopes: ["empty_repositories"]) }

      it "shows a message" do
        output = RepositoriesRenderer.new.render(system_description)

        expect(output).to include("There are no repositories.")
      end
    end
  end
end
