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

describe Machinery::ElementFilter do
  before(:each) do
    @path = "/unmanaged_files/files/name"
    @matcher1 = "/home/alfred"
    @matcher2 = "/var/cache"
  end

  describe "#initialize" do
    it "creates filter object" do
      filter = Machinery::ElementFilter.new(@path)
      expect(filter).to be_a(Machinery::ElementFilter)
    end

    it "creates filter object with one definition" do
      filter = Machinery::ElementFilter.new(@path, Machinery::Filter::OPERATOR_EQUALS, @matcher1)
      expect(filter.matchers).to eq(Machinery::Filter::OPERATOR_EQUALS => [@matcher1])
    end

    it "creates filter object with an array of definitions" do
      matcher = [@matcher1, @matcher2]
      filter = Machinery::ElementFilter.new(@path, Machinery::Filter::OPERATOR_EQUALS, matcher)
      expect(filter.matchers).to eq(Machinery::Filter::OPERATOR_EQUALS => matcher)
    end
  end

  describe "#add_matcher" do
    it "adds one matcher definition" do
      filter = Machinery::ElementFilter.new(@path)
      filter.add_matchers(Machinery::Filter::OPERATOR_EQUALS, @matcher1)
      expect(filter.matchers).to eq(Machinery::Filter::OPERATOR_EQUALS => [@matcher1])
    end

    it "adds two matcher definition" do
      filter = Machinery::ElementFilter.new(@path)
      filter.add_matchers(Machinery::Filter::OPERATOR_EQUALS, @matcher1)
      filter.add_matchers(Machinery::Filter::OPERATOR_EQUALS, @matcher2)
      expect(filter.matchers).to eq(Machinery::Filter::OPERATOR_EQUALS => [@matcher1, @matcher2])
    end

    it "adds an array matcher definition" do
      filter = Machinery::ElementFilter.new(@path)
      filter.add_matchers(Machinery::Filter::OPERATOR_EQUALS, [["md5", "size"]])
      expect(filter.matchers).to eq(Machinery::Filter::OPERATOR_EQUALS => [["md5", "size"]])
    end

    it "raises an exception when invalid operators are used" do
      filter = Machinery::ElementFilter.new(@path)
      expect {
        filter.add_matchers(">=", ["foo"])
      }.to raise_error(Machinery::Errors::InvalidFilter)
    end
  end

  describe "#matchers" do
    it "returns all matchers" do
      filter = Machinery::ElementFilter.new(@path, Machinery::Filter::OPERATOR_EQUALS, [@matcher1, @matcher2])
      expect(filter.matchers).to eq(Machinery::Filter::OPERATOR_EQUALS => ["/home/alfred", "/var/cache"])
    end
  end

  describe "#matches?" do
    context "with multiple operators" do
      it "works" do
        filter = Machinery::ElementFilter.new(@path)
        filter.add_matchers(Machinery::Filter::OPERATOR_EQUALS, @matcher1)
        filter.add_matchers(Machinery::Filter::OPERATOR_EQUALS_NOT, @matcher2)
        expect(filter.matches?(@matcher1)).to be(true)         # :== matches
        expect(filter.matches?("/something/else")).to be(true) # :!= matcher
        expect(filter.matches?(@matcher2)).to be(false)        # neither matcher matches
      end
    end

    context "with equals operator" do
      it "returns true on matching value" do
        filter = Machinery::ElementFilter.new(@path, Machinery::Filter::OPERATOR_EQUALS, @matcher1)
        expect(filter.matches?("/home/alfred")).
          to be(true)
      end

      it "returns false on non-matching value" do
        filter = Machinery::ElementFilter.new(@path, Machinery::Filter::OPERATOR_EQUALS, @matcher1)
        expect(filter.matches?("/home/berta")).
          to be(false)
      end

      it "returns true when one matcher matches" do
        filter = Machinery::ElementFilter.new(@path, Machinery::Filter::OPERATOR_EQUALS, [@matcher1, @matcher2])
        expect(filter.matches?("/home/alfred")).
          to be(true)
      end

      it "raises ElementFilterTypeMismatch when a String is matched against an Array" do
        filter = Machinery::ElementFilter.new(@path, Machinery::Filter::OPERATOR_EQUALS,
          [["array_element_a", "array_element_b"]])
        expect {
          filter.matches?("a string")
        }.to raise_error(Machinery::Errors::ElementFilterTypeMismatch)
      end

      describe "matches beginning of a value" do
        before(:each) do
          @filter = Machinery::ElementFilter.new("path", Machinery::Filter::OPERATOR_EQUALS, "/home/alfred/*")
        end

        it "returns false on shorter value" do
          expect(@filter.matches?("/home/alfred")).to be(false)
        end

        it "returns true on minimal match" do
          expect(@filter.matches?("/home/alfred/")).to be(true)
        end

        it "returns true on longer match" do
          expect(@filter.matches?("/home/alfred/and/berta")).to be(true)
        end

        it "returns true on value with star at the end" do
          expect(@filter.matches?("/home/alfred/*")).to be(true)
        end
      end

      context "matching arrays" do
        before(:each) do
          @filter = Machinery::ElementFilter.new("path", Machinery::Filter::OPERATOR_EQUALS, [["a", "b"]])
        end

        it "finds matches" do
          expect(@filter.matches?(Machinery::Array.new(["a", "b"]))).to be(true)
        end

        it "does not match on extra elements" do
          expect(@filter.matches?(Machinery::Array.new(["a", "b", "c"]))).to be(false)
        end

        it "does not match on missing elements" do
          expect(@filter.matches?(Machinery::Array.new(["a"]))).to be(false)
        end

        it "allows for filtering arrays with one element using a string filter" do
          filter = Machinery::ElementFilter.new("path", Machinery::Filter::OPERATOR_EQUALS, ["a"])
          expect(filter.matches?(Machinery::Array.new(["a"]))).to be(true)
          expect(filter.matches?(Machinery::Array.new(["a", "b"]))).to be(false)
        end
      end
    end

    context "with equals not operator" do
      it "returns false on matching value" do
        filter = Machinery::ElementFilter.new(@path, Machinery::Filter::OPERATOR_EQUALS_NOT, [@matcher1])
        expect(filter.matches?("/home/alfred")).
          to be(false)
      end

      it "returns true on non-matching value" do
        filter = Machinery::ElementFilter.new(@path, Machinery::Filter::OPERATOR_EQUALS_NOT, @matcher1)
        expect(filter.matches?("/home/berta")).
          to be(true)
      end

      it "returns true when one matcher doesn't match" do
        filter = Machinery::ElementFilter.new(@path, Machinery::Filter::OPERATOR_EQUALS_NOT, [@matcher2, @matcher1])
        expect(filter.matches?("/home/alfred")).
          to be(true)
      end

      describe "matches beginning of a value" do
        before(:each) do
          @filter = Machinery::ElementFilter.new("path", Machinery::Filter::OPERATOR_EQUALS_NOT, "/home/alfred/*")
        end

        it "returns true on shorter value" do
          expect(@filter.matches?("/home/alfred")).to be(true)
        end

        it "returns false on minimal match" do
          expect(@filter.matches?("/home/alfred/")).to be(false)
        end

        it "returns false on longer match" do
          expect(@filter.matches?("/home/alfred/and/berta")).to be(false)
        end

        it "returns false on value with star at the end" do
          expect(@filter.matches?("/home/alfred/*")).to be(false)
        end
      end

      context "matching arrays" do
        before(:each) do
          @filter = Machinery::ElementFilter.new("path", Machinery::Filter::OPERATOR_EQUALS_NOT, [["a", "b"]])
        end

        it "does not match equal arrays" do
          expect(@filter.matches?(Machinery::Array.new(["a", "b"]))).to be(false)
        end

        it "matches on extra elements" do
          expect(@filter.matches?(Machinery::Array.new(["a", "b", "c"]))).to be(true)
        end

        it "matches on missing elements" do
          expect(@filter.matches?(Machinery::Array.new(["a"]))).to be(true)
        end

        it "allows for filtering arrays with one element using a string filter" do
          filter = Machinery::ElementFilter.new("path", Machinery::Filter::OPERATOR_EQUALS_NOT, ["a"])
          expect(filter.matches?(Machinery::Array.new(["a"]))).to be(false)
          expect(filter.matches?(Machinery::Array.new(["a", "b"]))).to be(true)
        end
      end
    end
  end

  describe "filters_scope?" do
    specify {
      expect(Machinery::ElementFilter.new("/foo", Machinery::Filter::OPERATOR_EQUALS_NOT, "bar").
        filters_scope?("foo")).to be(true)
    }
    specify {
      expect(Machinery::ElementFilter.new("/foo", Machinery::Filter::OPERATOR_EQUALS_NOT, "bar").
        filters_scope?("foo_bar")).to be(false)
    }
  end

  describe "=" do
    it "works for equal objects" do
      expect(
        Machinery::ElementFilter.new("/foo", Machinery::Filter::OPERATOR_EQUALS, "bar") ==
          Machinery::ElementFilter.new("/foo", Machinery::Filter::OPERATOR_EQUALS, "bar")
      ).to be(true)
      expect(
        Machinery::ElementFilter.new("/foo", Machinery::Filter::OPERATOR_EQUALS, ["bar", "baz"]) ==
          Machinery::ElementFilter.new("/foo", Machinery::Filter::OPERATOR_EQUALS, ["bar", "baz"])
      ).to be(true)
    end

    it "works for different objects" do
      expect(
        Machinery::ElementFilter.new("/foo", Machinery::Filter::OPERATOR_EQUALS, "bar") ==
          Machinery::ElementFilter.new("/foo", Machinery::Filter::OPERATOR_EQUALS, "baz")
      ).to be(false)
      expect(
        Machinery::ElementFilter.new("/foo", Machinery::Filter::OPERATOR_EQUALS, ["bar", "baz"]) ==
          Machinery::ElementFilter.new("/foo", Machinery::Filter::OPERATOR_EQUALS, ["bar", "qux"])
      ).to be(false)
      expect(
        Machinery::ElementFilter.new("/foo", Machinery::Filter::OPERATOR_EQUALS, "bar") ==
          Machinery::ElementFilter.new("/baz", Machinery::Filter::OPERATOR_EQUALS, "bar")
      ).to be(false)
    end
  end

  describe "#dup" do
    it "creates a deep shallow copy" do
      element_filter = Machinery::ElementFilter.new("/foo", Machinery::Filter::OPERATOR_EQUALS, "bar")
      dupped = element_filter.dup

      dupped.matchers.clear
      expect(element_filter.matchers).to_not be_empty
    end
  end
end
