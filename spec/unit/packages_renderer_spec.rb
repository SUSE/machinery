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

describe PackagesRenderer do
  let(:system_description) {
    create_test_description(json: <<-EOF)
      {
        "packages": [
          {
            "name": "bash",
            "version": "4.2",
            "release": "1.0",
            "arch": "x86_64",
            "vendor": "openSUSE",
            "checksum": "7dfdd742a9b7d60c75bf4844d294716d"
          },
          {
            "name": "kernel-desktop",
            "version": "3.7.10",
            "release": "1.0",
            "arch": "i586",
            "vendor": "openSUSE",
            "checksum": "4a87f6b9ceae5d40a411fe52d0f17050"
          }
        ]
      }
    EOF
  }

  describe "#render" do
    it "prints a package list when scope packages is requested" do
      output = PackagesRenderer.new.render(system_description)

      expect(output).to include("bash-4.2-1.0.x86_64 (openSUSE)")
      expect(output).to include("kernel-desktop-3.7.10-1.0.i586 (openSUSE)")
    end
  end
end
