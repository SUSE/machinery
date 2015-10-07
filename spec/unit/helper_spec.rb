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

include GivenFilesystemSpecHelpers

describe Machinery do
  describe ".pluralize" do
    context "when pluralform is not given" do
      it "returns given singular text if the number is one" do
        expect(Machinery::pluralize(1, "text")).to eq "text"
      end
      it "returns given plural text if the number is zero" do
        expect(Machinery::pluralize(0, "text")).to eq "texts"
      end
      it "returns given plural text if the number is more than one" do
        expect(Machinery::pluralize(5, "text")).to eq "texts"
      end
      it "replaces %d by the count" do
        expect(Machinery::pluralize(5, "%d book")).to eq "5 books"
        expect(Machinery::pluralize(1, "%d book")).to eq "1 book"
      end
    end

    context "when pluralform is given" do
      it "returns given singular text if the number is one" do
        expect(Machinery::pluralize(1, "text", "texts")).to eq "text"
      end
      it "returns given plural text if the number is zero" do
        expect(Machinery::pluralize(0, "text", "texts")).to eq "texts"
      end
      it "returns given plural text if the number is more than one" do
        expect(Machinery::pluralize(5, "text", "texts")).to eq "texts"
      end
      it "replaces %d by the count" do
        expect(Machinery::pluralize(5, "%d person", "%d people")).to eq "5 people"
        expect(Machinery::pluralize(1, "%d person", "%d people")).to eq "1 person"
      end
    end
  end

  describe ".is_int?" do
    it "returns true if the string only consists numbers" do
      expect(Machinery::is_int?("12345")).to be(true)
      expect(Machinery::is_int?("1")).to be(true)
    end

    it "returns false if the string consist any chars than numbers" do
      expect(Machinery::is_int?(" 12345")).to be(false)
      expect(Machinery::is_int?("12456 ")).to be(false)
      expect(Machinery::is_int?("1a2")).to be(false)
      expect(Machinery::is_int?("1 ")).to be(false)
      expect(Machinery::is_int?(" 1")).to be(false)
      expect(Machinery::is_int?("")).to be(false)
    end
  end

  describe ".file_is_binary?" do
    use_given_filesystem

    it "detects xml file as non-binary" do
      expect(Machinery::file_is_binary?(given_file("xml_file"))).to be(false)
    end

    it "detects text file as non-binary" do
      expect(Machinery::file_is_binary?(given_file("text_file"))).to be(false)
    end

    it "detects binary file as binary" do
      expect(Machinery::file_is_binary?(given_file("binary_file"))).to be(true)
    end
  end

  describe ".scrub" do
    it "replaces all invalid UTF-8 characters to \uFFFD (invalid UTF-8 character)" do
      input = "a\255b"

      out = Machinery.scrub(input)
      expect(out).to eq("a\uFFFDb")
    end
  end
end

describe "#with_env" do
  it "sets the environment variable" do
    expect(ENV.include?("MACHINERY_TEST")).to be false
    with_env "MACHINERY_TEST" => "bla" do
      expect(ENV.include?("MACHINERY_TEST")).to be true
      expect(ENV.fetch("MACHINERY_TEST")).to eq("bla")
    end
  end

  it "resets the environment variables after run" do
    before_env = ENV
    with_env "MACHINERY_TEST" => "bla" do
      expect(ENV.include?("MACHINERY_TEST")).to be true
    end
    expect(ENV).to eq(before_env)
  end
end
