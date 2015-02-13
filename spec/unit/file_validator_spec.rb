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

describe FileValidator do
  describe "#validate" do
    before(:each) do
      @store = SystemDescriptionStore.new("spec/data/descriptions/validation")
      @store_v1 = SystemDescriptionStore.new("spec/data/descriptions/validation/v1")
    end

    describe "validating a format version 1 description" do
      it "throws error on invalid format v1 description" do
        manifest = Manifest.load("bad", @store_v1.manifest_path("bad"))

        validator = SystemDescriptionValidator.new(manifest.to_hash,
          @store_v1.description_path("bad"))
        errors = validator.validate_file_data
        expect(errors.join("\n")).to eq(<<EOT.chomp)
Scope 'config_files':
  * File 'spec/data/descriptions/validation/v1/bad/config_files/etc/postfix/main.cf' doesn't exist
Scope 'changed_managed_files':
  * File 'spec/data/descriptions/validation/v1/bad/changed_managed_files/usr/share/bash/helpfiles/read' doesn't exist
Scope 'unmanaged_files':
  * File 'spec/data/descriptions/validation/v1/bad/unmanaged_files/trees/root/.ssh.tgz' doesn't exist
EOT
      end
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
