# Copyright (c) 2013-2016 SUSE LLC
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

describe ContainerizedApp do
  let(:name) { "my_app" }
  let(:services) { double }
  let(:workloads) { double }

  subject { ContainerizedApp.new(name, workloads, services) }

  describe "get_binding" do
    let(:binding) { subject.get_binding }
    it "returns the class binding" do
      expect(eval("@name", binding)).to eq(name)
      expect(eval("@services", binding)).to eq(services)
      expect(eval("@workloads", binding)).to eq(workloads)
    end
  end
end
