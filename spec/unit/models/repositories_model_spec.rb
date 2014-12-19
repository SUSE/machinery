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

require_relative "../spec_helper"

describe "repositories model" do
  let(:scope) {
    json = create_test_description_json(scopes: ["repositories"])
    RepositoriesScope.from_json(JSON.parse(json)["repositories"])
  }

  it_behaves_like "Scope"

  specify { expect(scope.first).to be_a(Repository) }
end

describe Repository do
  subject { Repository.new }

  describe "#external_medium?" do
    it "returns true in case of a cd" do
      subject.url = "cd:///?devices=/dev/disk/by-id/ata-QEMU_DVD-ROM_QM00001"
      expect(subject.external_medium?).to be(true)
    end

    it "returns true in case of a cd" do
      subject.url = "dvd:///?devices=/dev/disk/by-id/ata-QEMU_DVD-ROM_QM00001"
      expect(subject.external_medium?).to be(true)
    end

    it "returns false in case of a network url" do
      subject.url = "http://download.opensuse.org/distribution/13.1/repo/oss/"
      expect(subject.external_medium?).to be(false)
    end

  end
end
