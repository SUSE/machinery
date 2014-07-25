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
        "packages": [
          {
            "name": "bash",
            "version": "4.2-68.1.5"
          },
          {
            "name": "kernel-desktop",
            "version": "3.7.10-1.16.1"
          }

        ]
      }
    EOF
    system_description = SystemDescription.from_json("name", json)
  }

  describe "#render" do
    it "prints a package list when scope packages is requested" do
      output = PackagesRenderer.new.render(system_description)

      expect(output).to include("bash (4.2-68.1.5)")
      expect(output).to include("kernel-desktop (3.7.10-1.16.1)")
    end
  end
end
