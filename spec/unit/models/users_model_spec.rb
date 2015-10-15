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

describe "users model" do
  let(:description) { create_test_description(scopes: ["users"]) }

  it_behaves_like "Scope" do
    let(:scope) { description.users }
  end

  specify { expect(description.users.first).to be_a(User) }

  describe "#compare_with" do
    it "does not consider last_changed_date changes" do
      users1 = description.users
      users2 = create_test_description(scopes: ["users"]).users
      users2.first.last_changed_date = 1

      expect(users1.compare_with(users2)).to eq([nil, nil, nil, users1])
    end
  end
end
