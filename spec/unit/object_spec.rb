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

describe Machinery::Object do
  class ObjectExampleObject < Machinery::Object; end

  it "assigns new values" do
    expect(subject.respond_to?(:foo)).to eq(false)
    subject.foo = "foo"
    expect(subject.foo).to eq("foo")
  end

  describe "initialize" do
    it "symbolizes keys" do
      object = Machinery::Object.new(
        "a" => "a",
        1   => "1"
      )
      expect(object.attributes.keys).to eq([:a, 1])
    end
  end

  describe "#==" do
    it "returns true when objects are identical" do
      equal = Machinery::Object.new(1 => "1") == Machinery::Object.new(1 => "1")
      expect(equal).to be(true)
    end

    it "returns false when objects are not identical" do
      equal = Machinery::Object.new(1 => "1") == Machinery::Object.new(1 => "2")
      expect(equal).to be(false)
    end

    it "returns false when objects are of different classes" do
      equal = Machinery::Object.new(1 => "1") == ObjectExampleObject.new(1 => "1")
      expect(equal).to be(false)
    end
  end

  describe "#from_json" do
    it "delegates to specialized class when the element class is set" do
      class FooObject < Machinery::Object; end
      class ObjectWithProperty < Machinery::Object
        has_property :foo, :class => FooObject
      end

      json_object = {foo: {bar: "bar"}, baz: "baz"}

      expected = ObjectWithProperty.new(
        foo: FooObject.new(bar: "bar"),
        baz: "baz"
      )
      expect(ObjectWithProperty.from_json(json_object)).to eq(expected)
    end

    it "uses generic classes when no element class is set" do
      json_object = {
        a: 1,
        b: {2 => "2"},
        c: [3, "3"]
      }

      expected = Machinery::Object.new(
        a: 1,
        b: Machinery::Object.new(2 => "2"),
        c: Machinery::Array.new([3, "3"])
      )
      expect(Machinery::Object.from_json(json_object)).to eq(expected)
    end
  end

  describe "#as_json" do
    it "serializes all objects to native ruby objects" do
      embedded_array = Machinery::Array.new(["a"])
      embedded_object = Machinery::Object.new(b: "b")
      object = ObjectExampleObject.new(
        a: embedded_array,
        b: embedded_object,
        c: 1
      )

      result = object.as_json
      expected = {
        a: ["a"],
        b: {b: "b"},
        c: 1
      }
      expect(result).to eq(expected)
    end
  end

  describe "#compare_with" do
    it "returns correct result when compared objects are equal" do
      a = Machinery::Object.new(:a => 42)
      b = Machinery::Object.new(:a => 42)

      comparison = a.compare_with(b)

      expect(comparison).to eq([nil, nil, Machinery::Object.new(:a => 42)])
    end

    it "returns correct result when compared objects aren't equal" do
      a = Machinery::Object.new(:a => 42)
      b = Machinery::Object.new(:b => 43)

      comparison = a.compare_with(b)

      expect(comparison).to eq([
        Machinery::Object.new(:a => 42),
        Machinery::Object.new(:b => 43),
        nil
      ])
    end
  end
end
