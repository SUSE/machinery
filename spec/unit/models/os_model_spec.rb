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

require_relative "../spec_helper"

describe Os do
  let(:scope) {
    json = create_test_description_json(scopes: ["os"])
    Os.from_json(JSON.parse(json)["os"])
  }

  it_behaves_like "Scope"

  describe "#scope_name" do
    it "works when constructed with factory" do
      expect(Os.for("some os").scope_name).to eq("os")
    end

    it "works on the base class" do
      expect(Os.new.scope_name).to eq("os")
    end

    it "works on sub classes" do
      expect(OsSles12.new.scope_name).to eq("os")
    end
  end
end
