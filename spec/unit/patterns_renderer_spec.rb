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

describe PatternsRenderer do
  let(:system_description) {
    json = <<-EOF
      {
        "patterns": [
          {
            "name": "base",
            "version": "11-38.44.33",
            "repository": "SLES11-SP3-Pool"
          },
          {
            "name": "Minimal",
            "version": "11-38.44.33",
            "repository": "SUSE-Linux-Enterprise-Server-11-SP3 11.3.3-1.138"
          }
        ]
      }
    EOF
    SystemDescription.from_json("name", json)
  }

  describe "#render" do
    it "prints a pattern list" do
      output = PatternsRenderer.new.render(system_description)

      expect(output).to include("base\n")
      expect(output).to include("Minimal\n")
    end
  end
end
