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

describe LocalSystem do
  include GivenFilesystemSpecHelpers
  use_given_filesystem
  capture_machinery_output
  let(:local_system) { LocalSystem.new }

  describe "#requires_root?" do
    it "returns true" do
      expect(local_system.requires_root?).to be(true)
    end
  end

  describe "#run_command" do
    it "executes commands locally" do
      cmd = ["ls", "/tmp"]
      expect(local_system).to receive(:with_utf8_locale).and_call_original
      expect(Cheetah).to receive(:run).with(*cmd)

      local_system.run_command(*cmd)
    end

    it "logs commands by default" do
      expect(LoggedCheetah).to receive(:run)

      local_system.run_command("ls")
    end

    it "does not log commands when :disable_logging is set" do
      expect(LoggedCheetah).to_not receive(:run)

      local_system.run_command("ls", disable_logging: true)
    end
  end

  describe "#retrieve_files" do
    it "retrives files via rsync from localhost" do
      expect(Cheetah).to receive(:run).with("rsync",  "--chmod=go-rwx", "--files-from=-", "/", "/tmp",  stdout: :capture, stdin: "/foo\n/bar" )

      local_system.retrieve_files(["/foo", "/bar"], "/tmp")
    end
  end

  describe "#read_file" do
    it "returns the file content if the file exists" do
      @existing_file = given_dummy_file
      expect(
        local_system.read_file(@existing_file)
      ).to_not be_empty
    end

    it "returns nil if the file does not exist" do
      expect(
        local_system.read_file("/does_not_exist")
      ).to be(nil)
    end
  end

  describe "#inject_file" do
    it "injects the file" do
      file = given_dummy_file
      destination = given_directory

      expected_file = File.join(destination, File.basename(file))

      expect(File.exists?(expected_file)).to be(false)

      local_system.inject_file(file, destination)
      expect(File.exists?(expected_file)).to be(true)
    end
  end

  describe "#remove_file" do
    it "removes the file" do
      file = given_dummy_file

      expect(File.exists?(file)).to be(true)

      local_system.remove_file(file)
      expect(File.exists?(file)).to be(false)
    end
  end

  describe ".validate_machinery_compatibility" do
    context "on hosts that can run machinery" do
      it "shows no warning" do
        allow(LocalSystem).to receive(:os).and_return(OsOpenSuse13_1.new)

        LocalSystem.validate_machinery_compatibility

        expect(captured_machinery_stderr).to eq ""
      end
    end

    context "on hosts that can not run machinery" do
      before(:each) do
        allow(LocalSystem).to receive(:os).and_return(OsSles11.new)
      end

      context "when plattform_support_check is enabled" do
        before(:each) do
          allow(Machinery::Config).to receive(:new).and_return(
            double(perform_support_check: true)
          )
        end

        it "shows a warning" do
          LocalSystem.validate_machinery_compatibility

          expect(captured_machinery_stderr).to include("platform we do not explicitly support")
        end

        it "lists all supported operating systems if the host is not supported" do
          LocalSystem.validate_machinery_compatibility

          expect(captured_machinery_stderr).to include(
            "openSUSE 13.2 (Harlequin)", "SUSE Linux Enterprise Server 12"
          )
        end

        it "shows how to turn off the warning" do
          LocalSystem.validate_machinery_compatibility

          expect(captured_machinery_stderr).to include(
            "'machinery config perform-support-check=false'"
          )
        end
      end

      context "when plattform_support_check is disabled" do
        it "shows no warning" do
          allow(Machinery::Config).to receive(:new).and_return(
            double(perform_support_check: false)
          )
          LocalSystem.validate_machinery_compatibility

          expect(captured_machinery_stderr).to eq("")
        end
      end
    end
  end

  describe ".validate_existence_of_package" do
    it "raises an Machinery::Errors::MissingRequirementsError error if the rpm-package isn't found" do
      allow(LocalSystem).to receive(:os).and_return(Os.new)
      output = <<-EOF
You need the package 'does_not_exist'.
You can install it by running `zypper install does_not_exist`.
EOF

      package = "does_not_exist"
      expect { LocalSystem.validate_existence_of_package(package) }.to raise_error(
        Machinery::Errors::MissingRequirement, output
      )
    end

    it "doesn't raise an error if the package exists" do
      expect { LocalSystem.validate_existence_of_package("bash") }.not_to raise_error
    end

    it "explains how to install a missing package from a module on SLES12" do
      allow(LocalSystem).to receive(:os).and_return(OsSles12.new)
      allow(Cheetah).to receive(:run).and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))

      expect {
        LocalSystem.validate_existence_of_package("python-glanceclient")
      }.to raise_error(Machinery::Errors::MissingRequirement, /Public Cloud Module/)
    end
  end

  describe ".validate_existence_of_command" do
    it "raises an Machinery::Errors::MissingRequirementsError error if the command isn't found" do
      allow(LocalSystem).to receive(:os).and_return(Os.new)
      output = <<-EOF
You need the command 'does_not_exist' from package 'not_installed_package'.
You can install it by running `zypper install not_installed_package`.
EOF

      command = "does_not_exist"
      package = "not_installed_package"
      expect { LocalSystem.validate_existence_of_command(command, package) }.to raise_error(
        Machinery::Errors::MissingRequirement, output
      )
    end

    it "doesn't raise an error if the command exists" do
      expect { LocalSystem.validate_existence_of_command("bash", "bash") }.not_to raise_error
    end
  end

  describe ".validate_existence_of_packages" do
    it "raises an error if packages doesn't exist" do
      allow(LocalSystem).to receive(:os).and_return(Os.new)

      output = <<-EOF
You need the packages 'does_not_exist','no_existing_package'.
You can install it by running `zypper install does_not_exist no_existing_package`.
EOF
      package = ["does_not_exist", "no_existing_package"]
      expect {
        LocalSystem.validate_existence_of_packages(package)
      }.to raise_error(Machinery::Errors::MissingRequirement, output)
    end
  end

  describe ".validate_build_compatibility" do
    before(:each) do
      allow(LocalSystem).to receive(:os).and_return(OsSles12.new)
    end

    it "raises an Machinery::UnsupportedHostForImageError error if the host for image build combination is unsupported" do
      # system which is unsupported to build on sle12 host
      system_description = create_test_description(json: <<-EOF)
        {
          "os": {
          "name": "SUSE Linux Enterprise Server 11"
          }
        }
        EOF

      expect { LocalSystem.validate_build_compatibility(system_description) }.to raise_error(Machinery::Errors::BuildFailed, /#{system_description.os.name}/)
    end

    it "doesn't raise if host and image builds a valid combination" do
      # system which is supported to build on sle12 host
      system_description = create_test_description(json: <<-EOF)
        {
          "os": {
          "name": "SUSE Linux Enterprise Server 12",
          "architecture": "x86_64"
          }
        }
        EOF

      expect { LocalSystem.validate_build_compatibility(system_description) }.not_to raise_error
    end
  end
end
