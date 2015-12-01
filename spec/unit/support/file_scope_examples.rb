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

shared_examples "FileScope" do
  initialize_system_description_factory_store

  let(:file_a) {
    {
      name: "foo"
    }
  }
  let(:file_b) {
    {
      name: "bar"
    }
  }
  let(:file_c) {
    {
      name: "baz"
    }
  }

  describe "#compare_with" do
    it "compares for equal objects" do
      a = scope.class.new(
        [file_a, file_b],
        extracted: true
      )
      b = scope.class.new(
        [file_a, file_b],
        extracted: true
      )

      comparison = a.compare_with(b)
      expect(comparison).to eq([nil, nil, nil, a])
    end

    it "works for differing objects" do
      a = scope.class.new(
        [file_a, file_b],
        extracted: true
      )
      b = scope.class.new(
        [file_c, file_b],
        extracted: false
      )

      comparison = a.compare_with(b)
      expect(comparison).to eq([
        scope.class.new([file_a], extracted: true),
        scope.class.new([file_c], extracted: false),
        nil,
        scope.class.new([file_b])
      ])
    end
  end
end
