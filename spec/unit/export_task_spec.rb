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

describe ExportTask do
  include FakeFS::SpecHelpers

  let(:exporter) { double(export_name: "name-type") }
  subject { ExportTask.new(exporter) }

  describe "#export" do
    it "writes the export" do
      expect(exporter).to receive(:write).with("/bar/name-type")
      expect(Machinery::Ui).to receive(:puts).with("Exported to '/bar/name-type'.")

      subject.export("/bar", {})
    end

    describe "when the output directory already exists" do
      let(:output_dir) { "/foo" }
      let(:export_dir) { "/foo/name-type" }
      let(:content) { "/foo/name-type/bar" }

      before(:each) do
        FileUtils.mkdir_p(export_dir)
        FileUtils.touch(content)
      end

      it "raises an error when --force is not given" do
        expect {
          subject.export(output_dir, force: false)
        }.to raise_error(Machinery::Errors::ExportFailed)
      end

      it "overwrites existing directory when --force is given" do
        expect(exporter).to receive(:write).with(export_dir)
        expect(Machinery::Ui).to receive(:puts).with("Exported to '#{export_dir}'.")
        expect {
          subject.export(output_dir, force: true)
        }.to_not raise_error

        expect(File.exists?(content)).to be(false)
      end
    end
  end
end
