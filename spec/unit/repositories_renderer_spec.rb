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

  describe "show" do
    it "prints a repository list" do
      output = RepositoriesRenderer.new.render(system_description)

      expected_output = <<EOT

  * openSUSE_13.1_OSS
    URI: http://download.opensuse.org/distribution/13.1/repo/oss/
    Alias: openSUSE_13.1_OSS
    Enabled: Yes
    Refresh: Yes
    Priority: 99
    Package Manager: zypp

  * openSUSE_13.1_NON_OSS
    URI: http://download.opensuse.org/distribution/13.1/repo/non-oss/
    Alias: openSUSE_13.1_NON_OSS_ALIAS
    Enabled: No
    Refresh: No
    Priority: 99
    Package Manager: zypp

  * SLES12-12-0
    URI: cd:///?devices=/dev/disk/by-id/ata-QEMU_DVD-ROM_QM00001
    Alias: SLES12-12-0
    Enabled: Yes
    Refresh: No
    Priority: 99
    Package Manager: zypp

EOT
      expect(output).to include(expected_output)
    end

    it "prints an empty list" do
      description = create_test_description(json: '{ "repositories": [] }')

      output = RepositoriesRenderer.new.render(description)

      expected_output = <<EOT
# Repositories

  System has no repositories

EOT
      expect(output).to eq(expected_output)
    end
  end
end
