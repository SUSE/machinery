# Copyright (c) 2013-2014 SUSE LLC
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

describe PackagesRenderer do
  let(:system_description) {
    json = <<-EOF
    {
      "repositories": [
      {
        "alias": "openSUSE-13.1-1.10",
        "name": "openSUSE-13.1-1.10",
        "repo_type": "yast2",
        "url": "cd:///?devices=/dev/disk/by-id/ata-HL-DT-ST_DVD+_-RW_GHA2N_KEID27K1340,/dev/sr0",
        "enabled": true,
        "autorefresh": false,
        "gpgcheck": true,
        "priority": 99
      },
      {
        "alias": "repo-debug",
        "name": "openSUSE-13.1-Debug",
        "repo_type": null,
        "url": "http://download.opensuse.org/debug/distribution/13.1/repo/oss/",
        "enabled": false,
        "autorefresh": true,
        "gpgcheck": true,
        "priority": 98
      }
    ]
    }
    EOF
    SystemDescription.from_json("name", json)
  }

  describe "show" do
    it "prints a repository list" do
      output = RepositoriesRenderer.new.render(system_description)

      expect(output).to include("openSUSE-13.1-1.10")
      expect(output).to include("/dev/sr0")
      expect(output).to include("Alias: openSUSE-13.1-1.10")
      expect(output).to include("Enabled: Yes")
      expect(output).to include("Refresh: No")
      expect(output).to include("Priority: 99")
      expect(output).to include("openSUSE-13.1-Debug")
      expect(output).to include("http://download.opensuse.org/debug/distribution/13.1/repo/oss")
      expect(output).to include("Alias: repo-debug")
      expect(output).to include("Enabled: No")
      expect(output).to include("Refresh: Yes")
      expect(output).to include("Priority: 98")
    end
  end
end
