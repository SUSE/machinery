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

describe Autoyast do
  let(:expected_profile) {
    File.read(File.join(Machinery::ROOT, "spec/data/autoyast/simple.xml"))
  }
  let(:description) {
    create_test_description(
      scopes: [
        "packages",
        "patterns",
        "repositories",
        "users_with_passwords",
        "groups",
        "services"
      ]
    )
  }

  describe "#profile" do
    it "creates the expected profile" do
      autoyast = Autoyast.new(description)

      expect(autoyast.profile).to eq(expected_profile)
    end
  end
end
