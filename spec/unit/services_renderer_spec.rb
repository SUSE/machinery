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

describe ServicesRenderer do
  let(:system_description_systemd) {
    create_test_description(json: <<-EOF)
      {
        "services": {
          "init_system": "systemd",
          "services": [
            {
              "name": "alsasound.service",
              "state": "static"
            },
            {
              "name": "autofs.service",
              "state": "disabled"
            },
            {
              "name": "syslog.socket",
              "state": "enabled"
            }]
        }
      }
    EOF
  }

  let(:system_description_sysvinit) {
    create_test_description(json: <<-EOF)
      {
        "services": {
          "init_system": "sysvinit",
          "services": [
            {
              "name": "alsasound",
              "state": "on"
            },
            {
              "name": "autofs",
              "state": "off"
            },
            {
              "name": "boot.isapnp",
              "state": "on"
            }]
        }
      }
    EOF
  }

  let(:expected_output_systemd) {
    <<-EOF
# Services

  * alsasound.service: static
  * autofs.service: disabled
  * syslog.socket: enabled

EOF
  }

  let(:expected_output_sysvinit) {
    <<-EOF
# Services

  * alsasound: on
  * autofs: off
  * boot.isapnp: on

EOF
  }

  describe "#render" do
    it "prints a list of systemd services" do
      output = ServicesRenderer.new.render(system_description_systemd)

      expect(output).to eq(expected_output_systemd)
    end

    it "prints a list of SysVinit services" do
      output = ServicesRenderer.new.render(system_description_sysvinit)

      expect(output).to eq(expected_output_sysvinit)
    end
  end
end
