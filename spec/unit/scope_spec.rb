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

describe Machinery::Scope do
  class SimpleScope < Machinery::Scope
    contains Machinery::Object
  end

  subject { SimpleScope.new }

  describe "#initialize" do
    let(:expected) {
      Machinery::Object.new("a" => 1)
    }

    it "can initialize from a json hash" do
      expect(SimpleScope.new("a" => 1).payload).to eq(expected)
    end

    it "can initialize from a payload object" do
      expect(
        SimpleScope.new(Machinery::Object.new("a" => 1)).payload
      ).to eq(expected)
    end
  end

  describe "#set_metadata" do
    it "sets a timestamp and hostname to the packages scope of the system description" do
      mytime = Time.now.utc.iso8601
      host = "192.168.122.216"

      expect(subject.meta).to be_nil

      subject.set_metadata(mytime, host)

      t = Time.utc(subject.meta.modified)
      expect(t.utc?).to eq(true)
      expect(subject.meta.modified).to eq(mytime)
      expect(subject.meta.hostname).to eq(host)
    end
  end

  describe "#compare_with" do
    it "returns correct result when compared objects are equal" do
      a = SimpleScope.new(1 => "1")
      b = SimpleScope.new(1 => "1")

      expected = [nil, nil, SimpleScope.new(1 => "1")]
      expect(a.compare_with(b)).to eq(expected)
    end

    it "returns correct result when compared objects aren't equal" do
      a = SimpleScope.new(1 => "1")
      b = SimpleScope.new(2 => "2")

      expected = [
        SimpleScope.new(1 => "1"),
        SimpleScope.new(2 => "2"),
        nil
      ]
      expect(a.compare_with(b)).to eq(expected)
    end
  end
end
