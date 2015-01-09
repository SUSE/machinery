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

require_relative "spec_helper"

describe Machinery::Array do
  class ArrayExampleObject; end
  class ArrayExampleArray < Machinery::Array
    has_elements class: ArrayExampleObject
  end

  describe "#from_json" do
    it "delegates to specialized class when the element class is set" do
      json_object = [1, 2]

      element1 = double
      element2 = double
      expect(ArrayExampleObject).to receive(:from_json).with(1).and_return(element1)
      expect(ArrayExampleObject).to receive(:from_json).with(2).and_return(element2)

      expected = ArrayExampleArray.new([element1, element2])
      expect(ArrayExampleArray.from_json(json_object)).to eq(expected)
    end

    it "uses generic classes when no element class is set" do
      json_object = [1, {2 => "2"}, [3, "3"]]

      expected = Machinery::Array.new(
        [
          1,
          Machinery::Object.new(2 => "2"),
          Machinery::Array.new([3, "3"])
        ]
      )
      expect(Machinery::Array.from_json(json_object)).to eq(expected)
    end
  end

  describe "#==" do
    it "returns true when equal" do
      equal = Machinery::Array.new(["a", "b", "c"]) == Machinery::Array.new(["a", "b", "c"])

      expect(equal).to be(true)
    end

    it "returns false when not equal" do
      equal = Machinery::Array.new(["a", "b", "c"]) == Machinery::Array.new(["a", "b", "d"])

      expect(equal).to be(false)
    end

    it "returns false when class differs equal" do
      equal = Machinery::Array.new(["a", "b", "c"]) == ArrayExampleArray.new(["a", "b", "c"])

      expect(equal).to be(false)
    end
  end

  describe "#hash" do
    it "returns the same hash for arrays with equivalent elements" do
      hash1 = Machinery::Array.new(["a", "b", "c"]).hash
      hash2 = Machinery::Array.new(["a", "b", "c"]).hash

      expect(hash1).to eq(hash2)
    end

    it "returns a different hash for arrays with different elements" do
      hash1 = Machinery::Array.new(["a", "b", "c"]).hash
      hash2 = Machinery::Array.new(["d", "e", "f"]).hash

      expect(hash1).not_to eq(hash2)
    end
  end

  describe "#-" do
    it "subtracts the elements" do
      a = ArrayExampleArray.new(["a", "b", "c"])
      b = ArrayExampleArray.new(["b"])
      result = a - b

      expect(result).to eq(ArrayExampleArray.new(["a", "c"]))
      expect(result).to be_a(ArrayExampleArray)
    end
  end

  describe "#&" do
    it "builds the intersection" do
      a = ArrayExampleArray.new(["a", "b"])
      b = ArrayExampleArray.new(["a", "c"])
      result = a & b

      expect(result).to eq(ArrayExampleArray.new(["a"]))
      expect(result).to be_a(ArrayExampleArray)
    end
  end

  describe "#as_json" do
    it "serializes all objects to native ruby objects" do
      embedded_array = ArrayExampleArray.new(["a"])
      embedded_object = Machinery::Object.new(b: "b")
      array = ArrayExampleArray.new([1, embedded_array, embedded_object])

      result = array.as_json
      expect(result).to eq([1, ["a"], {b: "b"}])
    end
  end

  describe "#compare_with" do
    it "returns correct result when compared arrays are equal" do
      a = Machinery::Array.new(["a", "b", "c"])
      b = Machinery::Array.new(["a", "b", "c"])
      comparison = a.compare_with(b)

      expect(comparison).to eq(
        [
          nil,
          nil,
          Machinery::Array.new(["a", "b", "c"])
        ]
      )
    end

    it "returns correct result when compared arrays aren't equal and don't have common elements" do
      a = Machinery::Array.new(["a", "b", "c"])
      b = Machinery::Array.new(["d", "e", "f"])
      comparison = a.compare_with(b)

      expect(comparison).to eq(
        [
          Machinery::Array.new(["a", "b", "c"]),
          Machinery::Array.new(["d", "e", "f"]),
          nil
        ]
      )
    end

    it "returns correct result when compared arrays aren't equal but have common elements" do
      a = Machinery::Array.new(["a", "b", "c", "d"])
      b = Machinery::Array.new(["a", "b", "e", "f"])
      comparison = a.compare_with(b)

      expect(comparison).to eq(
        [
          Machinery::Array.new(["c", "d"]),
          Machinery::Array.new(["e", "f"]),
          Machinery::Array.new(["a", "b"])
        ]
      )
    end

    it "treats empty arrays correctly" do
      not_empty = Machinery::Array.new(["a", "b", "c"])
      empty = Machinery::Array.new()

      comparison1 = empty.compare_with(not_empty)
      comparison2 = not_empty.compare_with(empty)
      comparison3 = empty.compare_with(empty)

      expect(comparison1).to eq([nil, Machinery::Array.new(["a", "b", "c"]), nil])
      expect(comparison2).to eq([Machinery::Array.new(["a", "b", "c"]), nil, nil])
      expect(comparison3).to eq([nil, nil, nil])
    end
  end
end
