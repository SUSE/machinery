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

describe "machinery@leap" do
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

  describe "inspect ubuntu_1404", matrix: "pending" do
    base = "ubuntu_1404"
    username = "root"
    password = "vagrant"

    let(:inspect_options) {
      "--remote-user=#{username}" if username != "root"
    }
    before(:all) do
      @subject_system = start_system(
        box: base,
        username: username,
        password: password
      )
      prepare_machinery_for_host(
        @machinery,
        @subject_system.ip,
        username: username,
        password: password
      )
    end

    include_examples "inspect os", base
    include_examples "inspect patterns", base
    include_examples "inspect users", base
    include_examples "inspect groups", base
  end
end
