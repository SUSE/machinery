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

describe SystemDescriptionValidator do
  describe "#validate_json" do
    it "raises SystemDescriptionError on invalid global data in a description" do
      expect {
        create_test_description(name: @name, json: <<-EOT)
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
        create_test_description(name: @name, json: <<-EOT)
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
        create_test_description(name: @name, json: <<-EOT)
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
        create_test_description(name: @name, json: <<-EOT)
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

    it "validates against the system description format version 1" do
      expect(File).to receive(:read).with(/schema\/v1/).at_least(:once).and_call_original
      expect(File).to_not receive(:read).with(/schema\/v2/)
      create_test_description(name: @name, json: <<-EOT)
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
      expect(File).to_not receive(:read).with(/schema\/v1/)
      expect(File).to receive(:read).with(/schema\/v2/).at_least(:once).and_call_original
      create_test_description(name: @name, json: <<-EOT)
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

    describe "config-files" do
      let(:path) { "spec/data/schema/validation_error/config_files/" }

      it "raises in case of missing package_version" do
        expected = <<EOF
In scope config_files: The property #0 (files) did not contain a required property of 'package_version'.
EOF
        expected.chomp!
        expect {
          create_test_description(name: @name,
            json: File.read("#{path}missing_attribute.json"))
        }.to raise_error(Machinery::Errors::SystemDescriptionError, expected)
      end

      it "raises in case of an unknown status" do
        expected = <<EOF
In scope config_files: The property #0 (files/status) of type Hash did not match any of the required schemas.
EOF
        expected.chomp!
        expect {
          create_test_description(name: @name,
            json: File.read("#{path}unknown_status.json"))
        }.to raise_error(Machinery::Errors::SystemDescriptionError, expected)
      end

      it "raises in case of a pattern mismatch" do
        expected = <<EOF
In scope config_files: The property #0 (files/mode/changes) of type Hash did not match any of the required schemas.
EOF
        expected.chomp!
        expect {
          create_test_description(name: @name,
            json: File.read("#{path}pattern_mismatch.json"))
        }.to raise_error(Machinery::Errors::SystemDescriptionError, expected)
      end

      it "raises for a deleted file in case of an empty changes array" do
        expected = <<EOF
In scope config_files: The property #0 (files/changes) of type Hash did not match any of the required schemas.
EOF
        expected.chomp!
        expect {
          create_test_description(name: @name,
            json: File.read("#{path}deleted_without_changes.json"))
        }.to raise_error(Machinery::Errors::SystemDescriptionError, expected)
      end
    end

    describe "unmanaged_files scope" do
      let(:path) { "spec/data/schema/validation_error/unmanaged_files/" }

      it "raises for extracted in case of unknown type" do
        expected = <<EOF
In scope unmanaged_files: The property #0 (files) of type Array did not match any of the required schemas.
EOF
        expected.chomp!
        expect {
          create_test_description(name: @name,
            json: File.read("#{path}/extracted_unknown_type.json"))
        }.to raise_error(Machinery::Errors::SystemDescriptionError, expected)
      end
    end
  end

  describe "#validate_file_data" do
    before(:each) do
      path = "spec/data/descriptions/validation"
      @store = SystemDescriptionStore.new(path)
    end

    describe "validate config file presence" do
      it "validates unextracted description" do
        expect {
          SystemDescription.load!("config-files-unextracted", @store)
        }.to_not raise_error
      end

      it "validates valid description" do
        expect {
          SystemDescription.load!("config-files-good", @store)
        }.to_not raise_error
      end

      it "throws error on invalid description" do
        expect {
          SystemDescription.load!("config-files-bad", @store)
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
          SystemDescription.load!("changed-managed-files-unextracted", @store)
        }.to_not raise_error
      end

      it "validates valid description" do
        expect {
          SystemDescription.load!("changed-managed-files-good", @store)
        }.to_not raise_error
      end

      it "throws error on invalid description" do
        expect {
          SystemDescription.load!("changed-managed-files-bad", @store)
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

    describe "validate changed managed file presence as warnings" do
      it "validates unextracted description" do
        expect(Machinery::Ui).to_not receive(:warn)
        SystemDescription.load("changed-managed-files-unextracted", @store)
      end

      it "validates valid description" do
        expect(Machinery::Ui).to_not receive(:warn)
        SystemDescription.load("changed-managed-files-good", @store)
      end

      it "throws a warning on invalid description" do
        expect(Machinery::Ui).to receive(:warn).with("Warning: File validation errors:")
        expect(Machinery::Ui).to receive(:warn).with(
          "Error validating description 'changed-managed-files-bad'\n\n"
        )
        expect(Machinery::Ui).to receive(:warn).with(
          [
            "Scope 'changed_managed_files':\n" \
            "  * File 'spec/data/descriptions/validation/changed-managed-files-bad/" \
            "changed_managed_files/usr/share/bash/helpfiles/read' doesn't exist"
          ]
        )

        SystemDescription.load("changed-managed-files-bad", @store)
      end
    end

    describe "validate unmanaged file presence" do
      it "validates unextracted description" do
        expect {
          SystemDescription.load!("unmanaged-files-unextracted", @store)
        }.to_not raise_error
      end

      it "validates valid description" do
        expect {
          SystemDescription.load!("unmanaged-files-good", @store)
        }.to_not raise_error
      end

      it "throws error on invalid description" do
        expect {
          SystemDescription.load!("unmanaged-files-bad", @store)
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
            SystemDescription.load!("changed-managed-files-good", @store)
          }.to_not raise_error
        end

        it "throws an error on file exists without meta data" do
          expect {
            SystemDescription.load!("changed-managed-files-additional-files",
              @store)
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
            SystemDescription.load!("config-files-good", @store)
          }.to_not raise_error
        end

        it "throws an error on file exists without meta data" do
          expect {
            SystemDescription.load!("config-files-additional-files", @store)
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
            SystemDescription.load!("unmanaged-files-good", @store)
          }.to_not raise_error
        end

        it "throws an error on file exists without meta data" do
          expect {
            SystemDescription.load!("unmanaged-files-additional-files", @store)
          }.to raise_error(Machinery::Errors::SystemDescriptionValidationFailed) do |error|
            expect(error.to_s).to include(
              "* File 'spec/data/descriptions/validation/unmanaged-files-additional-files/unmanaged_files/files.tgz' doesn't have meta data"
            )
          end
        end
      end
    end
  end
end
