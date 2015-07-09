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

describe FileDiff do
  initialize_system_description_factory_store

  subject { FileDiff }
  let(:description1) {
    create_test_description(
      name: "description1",
      store_on_disk: true,
      extracted_scopes: ["config_files"]
    )
  }
  let(:unextracted_description) {
    create_test_description(
      name: "description1",
      store_on_disk: true,
      scopes: ["config_files"]
    )
  }
  let(:description2) {
    description = create_test_description(
      name: "description2",
      store_on_disk: true,
      extracted_scopes: ["config_files"]
    )
    file = description.config_files.files.select(&:file?).first

    File.write(
      File.join(description.description_path, "config_files", file.name),
      "Other content\n"
    )
    description
  }

  describe "#diff" do
    it "returns nil if file is not available" do
      empty_description = create_test_description

      expect(
        subject.diff(description1, empty_description, "config_files", "/etc/cron tab")
      ).to be(nil)
    end

    it "returns nil if file was not extracted" do
      expect(
        subject.diff(description1, unextracted_description, "config_files", "/etc/cron tab")
      ).to be(nil)
    end

    it "raises an exception when it's asked to diff binary files" do
      expect_any_instance_of(Machinery::SystemFile).to receive(:binary?).and_return(true)
      expect {
        subject.diff(description1, description2, "config_files", "/etc/cron tab")
      }.to raise_error(Machinery::Errors::BinaryDiffError, /binary/)
    end

    it "returns an empty string if files are equal" do
      expect(
        subject.diff(description1, description1, "config_files", "/etc/cron tab").to_s
      ).to eq("")
    end

    it "returns the diff" do
      expected_diff = <<EOF
-Stub data for /etc/cron tab.
\\ No newline at end of file
+Other content
EOF
      expect(
        subject.diff(description1, description2, "config_files", "/etc/cron tab").to_s
      ).to eq(expected_diff)
    end
  end
end
