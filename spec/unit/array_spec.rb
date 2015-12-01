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
  class ArrayExampleObject < Machinery::Object; end
  class ArrayExampleArray < Machinery::Array
    has_attributes :foo, :bar
    has_elements class: ArrayExampleObject
  end

  let(:json_element_a) { { a: 1 } }
  let(:json_element_b) { { b: 2 } }
  let(:json_element_c) { { c: 3 } }
  let(:json_object) {
    [
      json_element_a,
      json_element_b,
      json_element_c
    ]
  }

  describe "#from_json" do
    describe "plain arrays" do
      it "delegates to specialized class when the element class is set" do
        json_object = [
          { a: 1 },
          { b: 2 }
        ]

        array = ArrayExampleArray.from_json(json_object)
        expect(array[0]).to eq(ArrayExampleObject.new(a: 1))
        expect(array[1]).to eq(ArrayExampleObject.new(b: 2))
      end

      it "uses generic classes when no element class is set" do
        json_object = [1, { 2 => "2" }, [3, "3"]]

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

    describe "complex arrays" do
      let(:array) {
        json_object = {
          "_attributes" => {
          },
          "_elements" => [
            1,
            2,
            {
              "_attributes" => {},
              "_elements" => [1]
            }
          ]
        }

        Machinery::Array.from_json(json_object)
      }

      it "makes the elements available as the payload" do
        expect(array.first).to eq(1)
        expect(array[1]).to eq(2)
        expect(array[2]).to eq(Machinery::Array.new([1]))
      end

      it "raises errors on unknown attributes" do
        expect {
          Machinery::Array.from_json({
            "_attributes" => {
              foo: "bar"
            },
            "_elements" => []
          })
        }.to raise_error(/Unknown properties.*foo/)
      end
    end
  end

  describe "#to_s" do
    it "returns the concatenated elements" do
      array = Machinery::Array.new(["a", "b", "c"])

      expect(array.to_s).to eq("a,b,c")
    end

    it "returns 'empty' when the array is empty" do
      expect(Machinery::Array.new.to_s).to eq("(empty)")
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
      equal = Machinery::Array.new(json_object) == ArrayExampleArray.new(json_object)

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
      a = ArrayExampleArray.new(json_object)
      b = ArrayExampleArray.new([json_element_b])
      result = a - b

      expect(result).to eq(ArrayExampleArray.new([json_element_a, json_element_c]))
      expect(result).to be_a(ArrayExampleArray)
    end
  end

  describe "#&" do
    it "builds the intersection" do
      a = ArrayExampleArray.new([json_element_a, json_element_b])
      b = ArrayExampleArray.new([json_element_a, json_element_c])
      result = a & b

      expect(result).to eq(ArrayExampleArray.new([json_element_a]))
      expect(result).to be_a(ArrayExampleArray)
    end
  end

  describe "#as_json" do
    it "serializes all objects to native ruby objects" do
      embedded_array = ArrayExampleArray.new([json_element_a])
      embedded_object = Machinery::Object.new(json_element_b)
      array = Machinery::Array.new([1, embedded_array, embedded_object])

      result = array.as_json
      expect(result).to eq(
        "_attributes" => {
        },
        "_elements" => [
          1,
          {
            "_attributes" => {},
            "_elements" => ["a" => 1]
          },
          { "b" => 2 }
        ]
      )
    end
  end

  describe "setter methods" do
    it "convert the payload to the data model" do
      array = ArrayExampleArray.new

      array << json_element_a
      array.push(json_element_b)
      array += [json_element_c]
      array.insert(0, json_element_a)

      expect(array).to be_a(ArrayExampleArray)
      expect(array.size).to eq(4)
      expect(array.all? { |element| element.is_a?(ArrayExampleObject) }).to be(true)
    end

    it "sets attributes" do
      array = ArrayExampleArray.new

      expect(array.foo).to be_nil
      expect(array.bar).to be_nil
      expect {
        array.baz
      }.to raise_error

      array.foo = "foo"
      array.bar = "bar"

      expect(array.foo).to eq("foo")
      expect(array.bar).to eq("bar")
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
          nil,
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
          nil,
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

      expect(comparison1).to eq([nil, Machinery::Array.new(["a", "b", "c"]), nil, nil])
      expect(comparison2).to eq([Machinery::Array.new(["a", "b", "c"]), nil, nil, nil])
      expect(comparison3).to eq([nil, nil, nil, nil])
    end

    it "compares the attributes as well" do
      a = ArrayExampleArray.new([], foo: "a", bar: "a")
      b = ArrayExampleArray.new([], foo: "b", bar: "b")
      c = ArrayExampleArray.new([], foo: "a", bar: "c")

      comparison1 = a.compare_with(b)
      comparison2 = a.compare_with(c)
      comparison3 = a.compare_with(a)

      expect(comparison1).to eq(
        [
          ArrayExampleArray.new([], foo: "a", bar: "a"),
          ArrayExampleArray.new([], foo: "b", bar: "b"),
          nil,
          nil
        ]
      )
      expect(comparison2).to eq(
        [
          ArrayExampleArray.new([], foo: "a", bar: "a"),
          ArrayExampleArray.new([], foo: "a", bar: "c"),
          nil,
          nil
        ]
      )
      expect(comparison3).to eq(
        [
          nil,
          nil,
          nil,
          ArrayExampleArray.new([], foo: "a", bar: "a")
        ]
      )
    end
  end

  describe "#scope=" do
    it "propagates the scope to its children" do
      scope = double
      json_object = [
        { a: 1 },
        { b: 2 }
      ]
      array = ArrayExampleArray.from_json(json_object)

      expect(array.scope).to be(nil)
      expect(array.first.scope).to be(nil)

      array.scope = scope

      expect(array.scope).to be(scope)
      expect(array.first.scope).to be(scope)
    end
  end
end
