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
    create_test_description(json: <<-EOF)
    {
      "repositories": [
      {
        "alias": "openSUSE-13.1-1.10",
        "name": "openSUSE-13.1-1.10",
        "type": "yast2",
        "url": "cd:///?devices=/dev/disk/by-id/ata-HL-DT-ST_DVD+_-RW_GHA2N_KEID27K1340,/dev/sr0",
        "enabled": true,
        "autorefresh": false,
        "gpgcheck": true,
        "priority": 99
      },
      {
        "alias": "repo-debug",
        "name": "openSUSE-13.1-Debug",
        "type": null,
        "url": "http://download.opensuse.org/debug/distribution/13.1/repo/oss/",
        "enabled": false,
        "autorefresh": true,
        "gpgcheck": true,
        "priority": 98
      }
    ]
    }
    EOF
  }

  describe "show" do
    it "prints a repository list" do
      output = RepositoriesRenderer.new.render(system_description)

      expected_output = <<EOT
# Repositories

  * openSUSE-13.1-1.10
    URI: cd:///?devices=/dev/disk/by-id/ata-HL-DT-ST_DVD+_-RW_GHA2N_KEID27K1340,/dev/sr0
    Alias: openSUSE-13.1-1.10
    Enabled: Yes
    Refresh: No
    Priority: 99

  * openSUSE-13.1-Debug
    URI: http://download.opensuse.org/debug/distribution/13.1/repo/oss/
    Alias: repo-debug
    Enabled: No
    Refresh: Yes
    Priority: 98

EOT
      expect(output).to eq(expected_output)
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
