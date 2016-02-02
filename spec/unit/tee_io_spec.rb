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

describe TeeIO do
  let(:io_object) { StringIO.new }
  subject { TeeIO.new(io_object) }

  it "is a StringIO object" do
    expect(subject.is_a?(StringIO)).to be(true)
  end

  describe "#write" do
    it "stores the content written" do
      subject.write("something")
      expect(subject.string).to include("something")
    end

    it "passes the content written to the io_object" do
      subject.write("something")
      expect(io_object.string).to include("something")
    end

    context "when a filter was initalized" do
      let(:filter_string) { "something to filter" }
      subject { TeeIO.new(io_object, filter_string) }

      it "filters strings from being forwarded to io_object" do
        subject.write(filter_string)
        expect(subject.string).to include(filter_string)
        expect(io_object.string).not_to include(filter_string)
      end

      it "only filters matching strings" do
        subject.write("anything")
        subject.write(filter_string)
        expect(subject.string).to include("anything")
        expect(io_object.string).to include("anything")
      end

      it "filters arrays of strings from being forwarded to io_object" do
        subject = TeeIO.new(io_object, ["filter1", filter_string])
        subject.write(filter_string)
        expect(subject.string).to include(filter_string)
        expect(io_object.string).not_to include(filter_string)
      end
    end
  end
end
