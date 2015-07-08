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

describe "machinery@openSUSE_13_1" do
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

  include_examples "CLI"
  include_examples "validate"
  include_examples "upgrade format"
  include_examples_for_platform(host)
end
