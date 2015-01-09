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

describe Machinery do
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
