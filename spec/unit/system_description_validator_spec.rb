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

describe SystemDescriptionValidator do
  describe "#validate_json" do
    it "raises SystemDescriptionError on invalid global data in a description" do
      expect {
        SystemDescription.from_json(@name, <<-EOT)
          {
            "meta": {
              "format_version": 2,
              "os": "invalid"
            }
          }
        EOT
      }.to raise_error(Machinery::Errors::SystemDescriptionError)
    end

    it "raises SystemDescriptionError on invalid scope data in a description" do
      expect {
        SystemDescription.from_json(@name, <<-EOT)
          {
            "meta": {
              "format_version": 2
            },
            "os": { }
          }
        EOT
      }.to raise_error(Machinery::Errors::SystemDescriptionError)
    end

    it "raises an error when encountering invalid enum values" do
      expected = <<EOF
In scope config_files: The property #0 (files/changes) of type Hash did not match any of the required schemas.
EOF
      expected.chomp!
      expect {
        SystemDescription.from_json(@name, <<-EOT)
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
              "format_version": 2,
              "config_files": {
                "modified": "2014-08-22T14:50:09Z",
                "hostname": "192.168.121.85"
              }
            }
          }
        EOT
        }.to raise_error(Machinery::Errors::SystemDescriptionError, expected)
    end

    it "does not raise an error when a changed-managed-file is 'replaced'" do
      expect {
        SystemDescription.from_json(@name, <<-EOT)
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
              "format_version": 2,
              "changed_managed_files": {
                "modified": "2014-08-12T09:12:54Z",
                "hostname": "host.example.com"
              }
            }
          }
        EOT
        }.not_to raise_error
    end

    describe "config-files" do
      let(:path) { "spec/data/schema/validation_error/config_files/" }

      it "raises in case of missing package_version" do
        expected = <<EOF
In scope config_files: The property #0 (files) did not contain a required property of 'package_version'.
EOF
        expected.chomp!
        expect { SystemDescription.
          from_json(@name,
            File.read("#{path}missing_attribute.json")) }.
          to raise_error(Machinery::Errors::SystemDescriptionError, expected)
      end

      it "raises in case of an unknown status" do
        expected = <<EOF
In scope config_files: The property #0 (files/status) of type Hash did not match any of the required schemas.
EOF
        expected.chomp!
        expect { SystemDescription.
          from_json(@name,
            File.read("#{path}unknown_status.json")) }.
          to raise_error(Machinery::Errors::SystemDescriptionError, expected)
      end

      it "raises in case of a pattern mismatch" do
        expected = <<EOF
In scope config_files: The property #0 (files/mode/changes) of type Hash did not match any of the required schemas.
EOF
        expected.chomp!
        expect { SystemDescription.
          from_json(@name,
            File.read("#{path}pattern_mismatch.json")) }.
          to raise_error(Machinery::Errors::SystemDescriptionError, expected)
      end

      it "raises for a deleted file in case of an empty changes array" do
        expected = <<EOF
In scope config_files: The property #0 (files/changes) of type Hash did not match any of the required schemas.
EOF
        expected.chomp!
        expect { SystemDescription.
          from_json(@name,
            File.read("#{path}deleted_without_changes.json")) }.
          to raise_error(Machinery::Errors::SystemDescriptionError, expected)
      end

    end

    describe "unmanaged_files scope" do
      let(:path) { "spec/data/schema/validation_error/unmanaged_files/" }

      it "raises for extracted in case of unknown type" do
        expected = <<EOF
In scope unmanaged_files: The property #0 (files) of type Array did not match any of the required schemas.
EOF
        expected.chomp!
        expect { SystemDescription.
          from_json(@name,
            File.read("#{path}/extracted_unknown_type.json")) }.
          to raise_error(Machinery::Errors::SystemDescriptionError, expected)
      end
    end
  end

  describe "#validate_file_data!" do
    before(:each) do
      path = "spec/data/descriptions/validation"
      @store = SystemDescriptionStore.new(path)
    end

    describe "validate config file presence" do
      it "validates unextracted description" do
        expect {
          @store.load("config-files-unextracted")
        }.to_not raise_error
      end

      it "validates valid description" do
        expect {
          @store.load("config-files-good")
        }.to_not raise_error
      end

      it "throws error on invalid description" do
        expect {
          @store.load("config-files-bad")
        }.to raise_error(Machinery::Errors::SystemDescriptionValidationFailed) do |error|
          expect(error.to_s).to eq(<<EOT
Error validating description 'config-files-bad'

Scope 'config_files':
  * File 'spec/data/descriptions/validation/config-files-bad/config_files/etc/postfix/main.cf' doesn't exist
EOT
          )
        end
      end
    end

    describe "validate changed managed file presence" do
      it "validates unextracted description" do
        expect {
          @store.load("changed-managed-files-unextracted")
        }.to_not raise_error
      end

      it "validates valid description" do
        expect {
          @store.load("changed-managed-files-good")
        }.to_not raise_error
      end

      it "throws error on invalid description" do
        expect {
          @store.load("changed-managed-files-bad")
        }.to raise_error(Machinery::Errors::SystemDescriptionValidationFailed) do |error|
          expect(error.to_s).to eq(<<EOT
Error validating description 'changed-managed-files-bad'

Scope 'changed_managed_files':
  * File 'spec/data/descriptions/validation/changed-managed-files-bad/changed_managed_files/usr/share/bash/helpfiles/read' doesn't exist
EOT
          )
        end
      end
    end

    describe "validate unmanaged file presence" do
      it "validates unextracted description" do
        expect {
          @store.load("unmanaged-files-unextracted")
        }.to_not raise_error
      end

      it "validates valid description" do
        expect {
          @store.load("unmanaged-files-good")
        }.to_not raise_error
      end

      it "throws error on invalid description" do
        expect {
          @store.load("unmanaged-files-bad")
        }.to raise_error(Machinery::Errors::SystemDescriptionValidationFailed) do |error|
          expect(error.to_s).to eq(<<EOT
Error validating description 'unmanaged-files-bad'

Scope 'unmanaged_files':
  * File 'spec/data/descriptions/validation/unmanaged-files-bad/unmanaged_files/trees/root/.ssh.tgz' doesn't exist
EOT
          )
        end
      end
    end

    describe "validate existence of meta data for extracted files" do
      before(:each) do
        path = "spec/data/descriptions/validation"
        @store = SystemDescriptionStore.new(path)
      end
      describe "for changed manged files" do
        it "validates existence of meta data" do
          expect {
            @store.load("changed-managed-files-good")
          }.to_not raise_error
        end

        it "throws an error on file exists without meta data" do
          expect {
            @store.load("changed-managed-files-additional-files")
          }.to raise_error(Machinery::Errors::SystemDescriptionValidationFailed) do |error|
            expect(error.to_s).to include(
              "* File 'spec/data/descriptions/validation/changed-managed-files-additional-files/changed_managed_files/lib/mkinitrd/scripts/setup-done.sh' doesn't have meta data",
              "* File 'spec/data/descriptions/validation/changed-managed-files-additional-files/changed_managed_files/usr/share/doc/packages/SUSE_SLES-release-DVD' doesn't have meta data"
            )
          end
        end
      end

      describe "for config files" do
        it "validates existence of meta data" do
          expect {
            @store.load("config-files-good")
          }.to_not raise_error
        end

        it "throws an error on file exists without meta data" do
          expect {
            @store.load("config-files-additional-files")
          }.to raise_error(Machinery::Errors::SystemDescriptionValidationFailed) do |error|
            expect(error.to_s).to include(
              "* File 'spec/data/descriptions/validation/config-files-additional-files/config_files/etc/postfix/main.cf' doesn't have meta data",
              "* File 'spec/data/descriptions/validation/config-files-additional-files/config_files/etc/ntp.conf' doesn't have meta data"
            )
          end
        end
      end

      describe "for unmanaged files" do
        it "validates existence of meta data" do
          expect {
            @store.load("unmanaged-files-good")
          }.to_not raise_error
        end

        it "throws an error on file exists without meta data" do
          expect {
            @store.load("unmanaged-files-additional-files")
          }.to raise_error(Machinery::Errors::SystemDescriptionValidationFailed) do |error|
            expect(error.to_s).to include(
              "* File 'spec/data/descriptions/validation/unmanaged-files-additional-files/unmanaged_files/files.tgz' doesn't have meta data"
            )
          end
        end
      end
    end
  end

  describe ".cleanup_json_error_message" do
    let (:validator)  { SystemDescriptionValidator.new(double) }
    describe "shows the correct position and reduces the clutter" do
      it "for missing attribute in unmanaged-files errors" do
        error = "The property '#/0/type/0/1/2/3/type/4/5' of type Array did not match any of the required schemas in schema 89d6911a-763e-51fd-8e35-257a1f31d377#"
        expected = "The property #5 of type Array did not match any of the required schemas."
        expect(validator.cleanup_json_error_message(error, "unmanaged_files")).
          to eq(expected)
      end

      it " for missing attribute in unmanaged_files and filters the type elements" do
        error = "The property '#/0/type/0/1/2/3/type/4/5/type/6/type/7/8/9/10/11/type/12/17/18/19/20/21/22/23/24/25/26/27/28/29/type/30/31/33/34/35/36/37/38/39/40/41/42/43/44/45/46/47/48/49/476/477/478/479/480/481/482/483/484/485/486/487/488/489/490/491/492/493/494/495/496/497/498/499/500/501/504/type/505/type/506/type/507/type/508/type/509/510/511/512/513/514/515/516/517/518/519/520/type/555' of type Array did not match any of the required schemas in schema 89d6911a-763e-51fd-8e35-257a1f31d377#"
        expected = "The property #555 of type Array did not match any of the required schemas."
        expect(validator.cleanup_json_error_message(error, "unmanaged_files")).
          to eq(expected)
      end

      it "for missing attribute in services" do
        error = "The property '#/services/2' did not contain a required property of 'state' in schema 73e30722-b9a4-573a-95a9-1f6882dd11a5#"
        expected = "The property #2 (services) did not contain a required property of 'state'."
        expect(validator.cleanup_json_error_message(error, "services")).
          to eq(expected)
      end

      it "for wrong status in services" do
        error = "The property '#/services/4/state' was not of a minimum string length of 1 in schema 73e30722-b9a4-573a-95a9-1f6882dd11a5#"
        expected = "The property #4 (services/state) was not of a minimum string length of 1."
        expect(validator.cleanup_json_error_message(error, "services")).
          to eq(expected)
      end

      it "for missing attribute in os" do
        error = "The property '#/' did not contain a required property of 'version' in schema 547e11fe-8e4b-574a-bec5-66ada4e5e2ec#"
        expected = "The property did not contain a required property of 'version'."
        expect(validator.cleanup_json_error_message(error, "os")).
          to eq(expected)
      end

      it "for wrong attribute type in users" do
        error = "The property '#/3/gid' of type String did not match one or more of the following types: integer, null in schema 769f5514-0330-592b-b538-87df746cb3d3#"
        expected = "The property #3 (gid) of type String did not match one or more of the following types: integer, null."
        expect(validator.cleanup_json_error_message(error, "users")).
          to eq(expected)
      end

      it "for unknown repository type and mentions the affected attribute 'type'" do
        error = "The property '#/4/type' value 0 did not match one of the following values: yast2, rpm-md, plaindir, null in schema 5ee44188-86f1-5823-92ac-e1068304cbf2#"
        expected = "The property #4 (type) value 0 did not match one of the following values: yast2, rpm-md, plaindir, null."
        expect(validator.cleanup_json_error_message(error, "repositories")).
          to eq(expected)
      end

      it "for unknown status in config-files" do
        error = "The property '#/0/1/status' of type Hash did not match any of the required schemas in schema 5257ca96-7f5c-5c72-b44e-80abca5b0f38#"
        expected = "The property #1 (status) of type Hash did not match any of the required schemas."
        expect(validator.cleanup_json_error_message(error, "config_files")).
          to eq(expected)
      end
    end
  end
end
