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

describe EnvironmentInspector do
  let(:description) {
    SystemDescription.new("systemname", SystemDescriptionStore.new)
  }
  let(:system) {
    double(
      requires_root?: false,
      host: "example.com",
      check_requirement: nil,
      type: "remote"
    )
  }
  let(:invalid_utf8) { "a\255b\nen_US.utf8" }
  let(:locale_list_without_utf8) {
    File.read(File.join(Machinery::ROOT, "spec/data/environment/locale_list_without_utf8"))
  }
  let(:locale_list_with_utf8) {
    File.read(File.join(Machinery::ROOT, "spec/data/environment/locale_list_with_utf8"))
  }
  subject { EnvironmentInspector.new(system, description) }

  describe "#inspect" do
    context "with a utf8 locale" do
      before(:each) do
        expect(system).to receive(:run_command).and_return(locale_list_with_utf8)
      end

      it "returns the utf8 locale if utf8 locale is available" do
        subject.inspect
        expect(description.environment.locale).to eq("en_US.utf8")
      end

      it "stores the system type" do
        subject.inspect
        expect(description.environment.system_type).to eq("remote")
      end
    end

    it "returns the C locale if no utf8 locale is available" do
      expect(system).to receive(:run_command).and_return(locale_list_without_utf8)

      subject.inspect
      expect(description.environment.locale).to eq("C")
    end

    it "does not fail in case of invalid byte squences in UTF-8" do
      expect(system).to receive(:run_command).and_return(invalid_utf8)

      subject.inspect
      expect(description.environment.locale).to eq("en_US.utf8")
    end
  end
end
