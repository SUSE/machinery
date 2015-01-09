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

shared_examples "Scope" do
  it "allows for setting the metadata" do
    expect(scope).to respond_to(:set_metadata)
  end

  it "knows about its scope name" do
    expect(scope).to respond_to(:scope_name)
  end

  it "knows whether it's extractable" do
    expect(scope).to respond_to(:is_extractable?)
  end
end
