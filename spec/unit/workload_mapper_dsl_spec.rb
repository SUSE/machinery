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

describe Machinery::WorkloadMapperDSL do
  let(:system_description) { double }
  subject { Machinery::WorkloadMapperDSL.new(system_description) }

  describe "#identify" do
    context "when no service is specified" do
      let(:clue) { "identify 'foo'" }
      specify "name and service equaliy" do
        subject.check_clue(clue)
        expect(subject.name).to eq("foo")
        expect(subject.service).to eq("foo")
      end
    end

    context "when service is specified" do
      let(:clue) { "identify 'foo', 'bar'" }
      it "sets the name and the service" do
        subject.check_clue(clue)
        expect(subject.name).to include("foo")
        expect(subject.service).to include("bar")
      end
    end
  end

  describe "#parameter" do
    let(:clue) { "parameter 'port', '1234'" }
    it "appends a parameter to the current workflow" do
      subject.check_clue(clue)

      expect(subject.parameters).to include("port" => "1234")
    end
  end

  describe "#extract" do
    let(:clue) { "extract '/foo/bar', 'faz'" }
    it "appends a folder meant to be extracted to the current workflow" do
      subject.check_clue(clue)

      expect(subject.data).to include("/foo/bar" => "faz")
    end
  end

  describe "#to_h" do
    it "returns an empty hash if service is nil" do
      mapper = Machinery::WorkloadMapperDSL.new(system_description)
      expect(mapper.to_h).to eq({})
    end
  end
end
