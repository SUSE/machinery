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

describe FileValidator do
  capture_machinery_output
  describe "#validate" do
    before(:each) do
      @store = Machinery::SystemDescriptionStore.new("spec/data/descriptions/validation")
      @store_v1 = Machinery::SystemDescriptionStore.new("spec/data/descriptions/validation/v1")
    end

    describe "validating a format version 1 description" do
      it "throws error on invalid format v1 description" do
        manifest = Manifest.load("bad", @store_v1.manifest_path("bad"))

        validator = FileValidator.new(manifest.to_hash, @store_v1.description_path("bad"))
        errors = validator.validate
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
          Machinery::SystemDescription.load!("changed-config-files-unextracted", @store)
        }.to_not raise_error
      end

      it "validates valid description" do
        expect {

          Machinery::SystemDescription.load!("changed-config-files-good", @store)
        }.to_not raise_error
      end

      it "throws error on invalid description" do
        expect {
          Machinery::SystemDescription.load!("changed-config-files-bad", @store)
        }.to raise_error(Machinery::Errors::SystemDescriptionValidationFailed) do |error|
          expect(error.to_s).to eq(<<EOT
Error validating description 'changed-config-files-bad'

Scope 'changed_config_files':
  * File 'spec/data/descriptions/validation/changed-config-files-bad/changed_config_files/etc/postfix/main.cf' doesn't exist
EOT
          )
        end
      end
    end

    describe "validate changed managed file presence" do
      it "validates unextracted description" do
        expect {
          Machinery::SystemDescription.load!("changed-managed-files-unextracted", @store)
        }.to_not raise_error
      end

      it "validates valid description" do
        expect {
          Machinery::SystemDescription.load!("changed-managed-files-good", @store)
        }.to_not raise_error
      end

      it "throws error on invalid description" do
        expect {
          Machinery::SystemDescription.load!("changed-managed-files-bad", @store)
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
        Machinery::SystemDescription.load("changed-managed-files-unextracted", @store)
      end

      it "validates valid description" do
        expect(Machinery::Ui).to_not receive(:warn)
        Machinery::SystemDescription.load("changed-managed-files-good", @store)
      end

      it "throws a warning on invalid description" do
        expected_output = <<-EOF.chomp
Warning: File validation errors:
Error validating description 'changed-managed-files-bad'


Scope 'changed_managed_files':
  * File 'spec/data/descriptions/validation/changed-managed-files-bad/changed_managed_files/usr/share/bash/helpfiles/read' doesn't exist

EOF
        Machinery::SystemDescription.load("changed-managed-files-bad", @store)
        expect(captured_machinery_output).to eq(expected_output)
      end
    end

    describe "validate unmanaged file presence" do
      it "validates unextracted description" do
        expect {
          Machinery::SystemDescription.load!("unmanaged-files-unextracted", @store)
        }.to_not raise_error
      end

      it "validates valid description" do
        expect {
          Machinery::SystemDescription.load!("unmanaged-files-good", @store)
        }.to_not raise_error
      end

      it "throws error on invalid description" do
        expect {
          Machinery::SystemDescription.load!("unmanaged-files-bad", @store)
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
        @store = Machinery::SystemDescriptionStore.new(path)
      end
      describe "for changed manged files" do
        it "validates existence of meta data" do
          expect {
            Machinery::SystemDescription.load!("changed-managed-files-good", @store)
          }.to_not raise_error
        end

        it "throws an error on file exists without meta data" do
          expect {
            Machinery::SystemDescription.load!("changed-managed-files-additional-files",
              @store)
          }.to raise_error(Machinery::Errors::SystemDescriptionValidationFailed) do |error|
            expect(error.to_s).to include(
              "* File 'spec/data/descriptions/validation/changed-managed-files-additional-files/changed_managed_files/lib/mkinitrd/scripts/setup-done.sh' doesn't have meta data",
              "* File 'spec/data/descriptions/validation/changed-managed-files-additional-files/changed_managed_files/usr/share/doc/packages/SUSE_SLES-release-DVD' doesn't have meta data"
            )
          end
        end
      end

      describe "for changed configuration files" do
        it "validates existence of meta data" do
          expect {
            Machinery::SystemDescription.load!("changed-config-files-good", @store)
          }.to_not raise_error
        end

        it "throws an error on file exists without meta data" do
          expect {
            Machinery::SystemDescription.load!("changed-config-files-additional-files", @store)
          }.to raise_error(Machinery::Errors::SystemDescriptionValidationFailed) do |error|
            expect(error.to_s).to include(
              "* File 'spec/data/descriptions/validation/changed-config-files-additional-files/changed_config_files/etc/postfix/main.cf' doesn't have meta data",
              "* File 'spec/data/descriptions/validation/changed-config-files-additional-files/changed_config_files/etc/ntp.conf' doesn't have meta data"
            )
          end
        end
      end

      describe "for unmanaged files" do
        it "validates existence of meta data" do
          expect {
            Machinery::SystemDescription.load!("unmanaged-files-good", @store)
          }.to_not raise_error
        end

        it "throws an error on file exists without meta data" do
          expect {
            Machinery::SystemDescription.load!("unmanaged-files-additional-files", @store)
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
