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

describe UnmanagedFilesInspector do
  describe "runs helper" do
    let(:system) { double(arch: "x86_64", run_command: "/root/machinery-helper") }
    let(:description) { SystemDescription.new("systemname", SystemDescriptionStore.new) }
    let(:inspector) { UnmanagedFilesInspector.new(system, description) }

    before(:each) do
      allow(system).to receive(:has_command?).and_return(true)
      allow(system).to receive(:check_requirement)

      allow_any_instance_of(MachineryHelper).to receive(:can_help?).and_return(true)
      expect_any_instance_of(MachineryHelper).to receive(:inject_helper)
      expect_any_instance_of(MachineryHelper).to receive(:remove_helper)
      expect_any_instance_of(MachineryHelper).to receive(:has_compatible_version?).and_return(true)
    end

    it "inspects unamanged-files" do
      expect_any_instance_of(MachineryHelper).to receive(:run_helper) do |_instance, scope|
        expect(scope).to be_a(UnmanagedFilesScope)
      end

      inspector.inspect(Filter.from_default_definition("inspect"))
    end

    context "when the --extract-metadata option is given" do
      it "inspects and extracts metadata for unmanaged-files" do
        expect_any_instance_of(MachineryHelper).to receive(:run_helper) do |_instance, scope, args|
          expect(scope).to be_a(UnmanagedFilesScope)
          expect(args).to eq("--extract-metadata")
        end

        inspector.inspect(Filter.from_default_definition("inspect"), extract_metadata: true)
      end
    end
  end
end
