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

  describe ".os" do
    before(:each) do
      expect_any_instance_of(OsInspector).to receive(:inspect) do |instance|
        system_description = create_test_description(json: <<-EOF)
        {
          "os": {
            "name": "SUSE Linux Enterprise Server 12"
          }
        }
        EOF
        instance.description.os = system_description.os
      end
    end

    it "returns os object for local host" do
      expect(LocalSystem.os).to be_a(OsSles12)
    end
  end

  describe "#requires_root?" do
    it "returns true" do
      expect(local_system.requires_root?).to be(true)
    end
  end

  describe "#run_command" do
    it "executes commands locally" do
      cmd = ["ls", "/tmp"]
      expect(local_system).to receive(:with_c_locale).and_call_original
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

  describe ".validate_machinery_compatibility" do
    it "returns true on hosts that can run machinery" do
      allow(LocalSystem).to receive(:os).and_return(OsOpenSuse13_1.new)

      expect {
        LocalSystem.validate_machinery_compatibility
      }.not_to raise_error
    end

    it "shows a warning on hosts that can not run machinery" do
      allow(LocalSystem).to receive(:os).and_return(OsSles11.new)
      LocalSystem.validate_machinery_compatibility

      expect(captured_machinery_output).to include(
        "You are running Machinery on a platform we do not explicitly support and test." \
        " It still could work very well. If you run into issues or would like to provide us feedback, " \
        "you are welcome to file an issue at https://github.com/SUSE/machinery/issues/new" \
        "or write an email to machinery@lists.suse.com. \n" \
        "Oficially supported operating systems are:"
        )
      expect(captured_machinery_output).to include("SUSE Linux Enterprise Server 12")
    end

    it "lists all supported operating systems if the host is not supported" do
      allow(LocalSystem).to receive(:os).and_return(OsSles11.new)
      LocalSystem.validate_machinery_compatibility

      expect(captured_machinery_output).to include(
        ": SUSE Linux Enterprise Server 12, openSUSE 13.1 (Bottle)," \
          " openSUSE 13.2 (Harlequin), openSUSE Tumbleweed"
        )
    end
  end

  describe ".validate_existence_of_package" do
    it "raises an Machinery::Errors::MissingRequirementsError error if the rpm-package isn't found" do
      allow(LocalSystem).to receive(:os).and_return(Os.new)

      package = "does_not_exist"
      expect { LocalSystem.validate_existence_of_package(package) }.to raise_error(Machinery::Errors::MissingRequirement, /#{package}/)
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
