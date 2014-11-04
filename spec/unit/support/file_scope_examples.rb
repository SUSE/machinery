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

shared_examples "FileScope" do
  describe "#compare_with" do
    it "compares for equal objects" do
      a = scope.class.new(
        extracted: true,
        files: Machinery::Array.new([1, 2])
      )
      b = scope.class.new(
        extracted: true,
        files: Machinery::Array.new([1, 2])
      )

      comparison = a.compare_with(b)
      expect(comparison).to eq([nil, nil, a])
    end

    it "works for differing objects" do
      a = scope.class.new(
        extracted: true,
        files: Machinery::Array.new([1, 2])
      )
      b = scope.class.new(
        extracted: false,
        files: Machinery::Array.new([3, 2])
      )

      comparison = a.compare_with(b)
      expect(comparison).to eq([
        scope.class.new(extracted: true, files: Machinery::Array.new([1])),
        scope.class.new(extracted: false, files: Machinery::Array.new([3])),
        scope.class.new(files: Machinery::Array.new([2]))
      ])
    end
  end
end
