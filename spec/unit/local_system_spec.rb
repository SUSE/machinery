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

describe LocalSystem do
  include GivenFilesystemSpecHelpers
  use_given_filesystem

  let(:local_system) { LocalSystem.new }

  describe ".os_object" do
    before(:each) do
      expect_any_instance_of(OsInspector).to receive(:inspect) do |instance, system, description|
        system_description = create_test_description(json: <<-EOF)
        {
          "os": {
            "name": "SUSE Linux Enterprise Server 12"
          }
        }
        EOF
        description.os = system_description.os
      end
    end

    it "returns os object for local host" do
      expect(LocalSystem.os_object).to be_a(OsSles12)
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

      local_system.run_command("ls", :disable_logging => true)
    end
  end

  describe "#retrieve_files" do
    it "retrives files via rsync from localhost" do
      expect(Cheetah).to receive(:run).with("rsync",  "--chmod=go-rwx", "--files-from=-", "/", "/tmp",  :stdout => :capture, :stdin => "/foo\n/bar" )

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
end
