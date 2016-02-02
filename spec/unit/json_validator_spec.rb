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

describe JsonValidator do
  describe "#validate" do
    it "validates against the system description format version 1" do
      expect_any_instance_of(JsonValidator).to receive(:global_schema).with(1).and_call_original
      expect_any_instance_of(JsonValidator).to_not receive(:global_schema).with(2)
      JsonValidator.new(JSON.parse(<<-EOT)).validate
          {
            "meta": {
              "format_version": 1,
              "changed_managed_files": {
                "modified": "2014-08-12T09:12:54Z",
                "hostname": "host.example.com"
              }
            }
          }
      EOT
    end

    it "validates against the system description format version 2" do
      expect_any_instance_of(JsonValidator).to_not receive(:global_schema).with(1)
      expect_any_instance_of(JsonValidator).to receive(:global_schema).with(2).and_call_original
      JsonValidator.new(JSON.parse(<<-EOT)).validate
        {
          "meta": {
            "format_version": 2,
            "changed_managed_files": {
              "modified": "2014-08-12T09:12:54Z",
              "hostname": "host.example.com"
            }
          }
        }
      EOT
    end
    it "complains about invalid global data in a description" do
      errors = JsonValidator.new(JSON.parse(<<-EOT)).validate
        {
          "meta": {
            "format_version": 2,
            "os": "invalid"
          }
        }
      EOT

      expect(errors).to_not be_empty
    end
  end

  describe "#validate_scope" do
    it "complains about invalid scope data in a description" do
      errors = JsonValidator.new(JSON.parse(<<-EOT)).validate
        {
          "os": {},
          "meta": {
            "format_version": 2
          }
        }
      EOT

      expect(errors.length).to eq(3)
    end

    it "raises an error when encountering invalid enum values" do
      expected = <<EOF
In scope config_files: The property #0 (files/changes) of type Hash did not match any of the required schemas.
EOF

      errors = JsonValidator.new(JSON.parse(<<-EOT)).validate
        {
          "config_files": {
            "extracted": true,
            "files": [
              {
                "name": "/etc/crontab",
                "package_name": "cronie",
                "package_version": "1.4.8",
                "status": "changed",
                "changes": [
                  "invalid"
                ],
                "user": "root",
                "group": "root",
                "mode": "644"
              }
            ]
          },
          "meta": {
            "format_version": 2
          }
        }
      EOT

      expect(errors.first).to eq(expected.chomp)
    end

    it "does not raise an error when a changed-managed-file is 'replaced'" do
      errors = JsonValidator.new(JSON.parse(<<-EOT)).validate
        {
          "changed_managed_files": {
            "extracted": true,
            "files": [
              {
                "name": "/etc/libvirt",
                "package_name": "libvirt-client",
                "package_version": "1.1.2",
                "status": "changed",
                "changes": [
                  "replaced"
                ],
                "mode": "700",
                "user": "root",
                "group": "root"
              }
            ]
          },
          "meta": {
            "format_version": 2
          }
        }
      EOT

      expect(errors).to be_empty
    end

    context "config-files" do
      let(:path) { "spec/data/schema/validation_error/config_files/" }

      it "raises in case of missing package_version" do
        expected = <<EOF
In scope config_files: The property #0 (_elements) did not contain a required property of 'package_version'.
EOF
        expected.chomp!
        errors = JsonValidator.new(
          JSON.parse(File.read("#{path}missing_attribute.json"))
        ).validate
        expect(errors.first).to eq(expected)
      end

      it "raises in case of an unknown status" do
        expected = <<EOF
In scope config_files: The property #0 (_elements/status) of type Hash did not match any of the required schemas.
EOF
        expected.chomp!
        errors = JsonValidator.new(
          JSON.parse(File.read("#{path}unknown_status.json"))
        ).validate
        expect(errors.first).to eq(expected)
      end

      it "raises in case of a pattern mismatch" do
        expected = <<EOF
In scope config_files: The property #0 (_elements/mode/changes) of type Hash did not match any of the required schemas.
EOF
        expected.chomp!
        errors = JsonValidator.new(
          JSON.parse(File.read("#{path}pattern_mismatch.json"))
        ).validate
        expect(errors.first).to eq(expected)
      end

      it "raises for a deleted file in case of an empty changes array" do
        expected = <<EOF
In scope config_files: The property #0 (_elements/changes) of type Hash did not match any of the required schemas.
EOF
        expected.chomp!
        errors = JsonValidator.new(
          JSON.parse(File.read("#{path}deleted_without_changes.json"))
        ).validate
        expect(errors.first).to eq(expected)
      end
    end

    context "unmanaged_files scope" do
      let(:path) { "spec/data/schema/validation_error/unmanaged_files/" }

      it "raises for extracted in case of unknown type" do
        expected = <<EOF
In scope unmanaged_files: The property #0 (_elements) of type Array did not match any of the required schemas.
EOF
        expected.chomp!
        errors = JsonValidator.new(
          JSON.parse(File.read("#{path}extracted_unknown_type.json"))
        ).validate
        expect(errors.first).to eq(expected)
      end
    end
  end
end
