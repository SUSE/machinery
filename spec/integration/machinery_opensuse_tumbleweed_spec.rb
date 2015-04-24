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

describe "machinery@openSUSE Tumbleweed" do
  let(:machinery_config) {
    {
      machinery_dir: "/home/vagrant/.machinery",
      owner: "vagrant",
      group: "vagrant"
    }
  }
  let(:machinery_command) { "machinery" }

  before(:all) do
    @machinery = start_system(box: "machinery_tumbleweed")
  end

  include_examples "CLI"
  include_examples "kiwi export"
  include_examples "autoyast export"
  include_examples "validate"
  include_examples "upgrade format"
  include_examples "generate html"
  include_examples "inspect", ["opensuse_tumbleweed"]
end
