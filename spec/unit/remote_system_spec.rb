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

describe RemoteSystem do
  let(:remote_system) { RemoteSystem.new("remotehost") }

  describe "#initialize" do
    it "raises ConnectionFailed when it can't connect" do
      expect(Cheetah).to receive(:run).with(
        "ssh", "-q", "-o", "BatchMode=yes", "root@example.com", ":"
      ).and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))

      expect {
        RemoteSystem.new("example.com")
      }.to raise_error(Machinery::Errors::SshConnectionFailed, /SSH/)
    end
  end

  context "connecting to a remote system" do
    before(:each) do
      allow_any_instance_of(RemoteSystem).to receive(:connect)
    end

    describe "#requires_root?" do
      it "returns false" do
        expect(remote_system.requires_root?).to be(false)
      end
    end

    describe "#run_command" do
      it "executes commands via ssh" do
        expect(Cheetah).to receive(:run).with(
          "ssh", "root@remotehost", "LC_ALL=en_US.utf8", "ls", "/tmp", {}
        )

        remote_system.run_command("ls", "/tmp")
      end

      it "executes piped commands via ssh" do
        expect(Cheetah).to receive(:run).with(
          "ssh", "root@remotehost", "LC_ALL=en_US.utf8", "ls", "/tmp", "|", "grep", "foo",
            "|", "wc", "-l", {}
        )

        remote_system.run_command(["ls", "/tmp"], ["grep", "foo"], ["wc", "-l"])
      end

      it "logs commands by default" do
        expect(LoggedCheetah).to receive(:run)

        remote_system.run_command("ls")
      end

      it "does not log commands when :disable_logging is set" do
        expect(LoggedCheetah).to_not receive(:run)
        expect(Cheetah).to receive(:run)

        remote_system.run_command("ls", disable_logging: true)
      end

      it "adheres to the remote_user option" do
        expect(Cheetah).to receive(:run).with(
          "ssh", "machinery@remotehost", "LC_ALL=en_US.utf8", "ls", "/tmp", {}
        )

        remote_system.remote_user = "machinery"
        remote_system.run_command("ls", "/tmp")
      end

      it "uses sudo when necessary" do
        expect(Cheetah).to receive(:run).with(
          "ssh", "machinery@remotehost", "sudo", "-n", "LC_ALL=en_US.utf8",
            "ls", "/tmp", privileged: true
        )

        remote_system.remote_user = "machinery"
        remote_system.run_command("ls", "/tmp", privileged: true)
      end

      it "raises an exception if the user is not allowed to run sudo" do
        expect(Cheetah).to receive(:run).with(
          "ssh", "machinery@remotehost", "sudo", "-n", "LC_ALL=en_US.utf8", "ls", "/tmp",
            privileged: true
        ).and_raise(Cheetah::ExecutionFailed.new(nil, 1, "", "sudo: a password is required"))

        remote_system.remote_user = "machinery"
        expect {
          remote_system.run_command("ls", "/tmp", privileged: true)
        }.to raise_error(Machinery::Errors::InsufficientPrivileges,
          /sudo isn't configured on the inspected host/
        )
      end
    end

    describe "#retrieve_files" do
      it "retrieves files via rsync from a remote host" do
        expect(Cheetah).to receive(:run).with(
          "rsync", "-e", "ssh", "--chmod=go-rwx", "--files-from=-", "--rsync-path=rsync",
          "root@remotehost:/", "/tmp",
          stdout: :capture,
          stdin: "/foo\n/bar"
        )

        remote_system.retrieve_files(["/foo", "/bar"], "/tmp")
      end

      it "retrieves files via sudo rsync from a remote host when non-root access is used" do
        expect(Cheetah).to receive(:run) do |*args|
          expect(args).to include("--rsync-path=sudo -n rsync")
        end

        remote_system.remote_user = "machinery"
        remote_system.retrieve_files(["/foo", "/bar"], "/tmp")
      end
    end

    describe "#read_file" do
      it "retrieves the content of the remote file" do
        expect(remote_system).to receive(:run_command).and_return("foo")

        expect(remote_system.read_file("/foo")).to eq("foo")
      end

      it "returns nil when the file does not exist" do
        status = double(exitstatus: 1)
        expect(remote_system).to receive(:run_command).
          and_raise(Cheetah::ExecutionFailed.new(nil, status, nil, nil))

        expect(remote_system.read_file("/foo")).to be_nil
      end
    end

    describe "#inject_file" do
      it "copies a file via scp" do
        expect(Cheetah).to receive(:run).with("scp", "/usr/foobar", "root@remotehost:/tmp")
        remote_system.inject_file("/usr/foobar", "/tmp")
      end
    end

    describe "#remove_file" do
      it "removes a file" do
        expect(remote_system).to receive(:run_command).with(
          "rm", "/tmp/foo", privileged: true
        )
        remote_system.remove_file("/tmp/foo")
      end
    end
  end
end
