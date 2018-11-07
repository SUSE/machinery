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

describe Machinery::RemoteSystem do
  let(:remote_system) { Machinery::RemoteSystem.new("remotehost", options) }
  let(:remote_system_with_sudo) { Machinery::RemoteSystem.new("remotehost", remote_user: "user") }
  let(:options) { {} }

  describe "#initialize" do
    it "raises ConnectionFailed when it can't connect" do
      expect(Cheetah).to receive(:run).with(
        "ssh", any_args
      ).and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))

      expect {
        remote_system
      }.to raise_error(Machinery::Errors::SshConnectionFailed, /SSH/)
    end

    context "sudo is required" do
      before do
        allow_any_instance_of(Machinery::RemoteSystem).to receive(:check_connection)
      end

      it "checks if sudo is available" do
        expect(Machinery::LoggedCheetah).to receive(:run)
        expect_any_instance_of(Machinery::RemoteSystem).
          to receive(:check_requirement).with("sudo", "-h")
        remote_system_with_sudo
      end

      it "raises an exception if the user is not allowed to run sudo" do
        expect(Machinery::LoggedCheetah).to receive(:run).with(
          "ssh", any_args
        ).and_raise(
          Cheetah::ExecutionFailed.new(
            nil, double(exitstatus: 1), "", "sudo: a password is required"
          )
        )

        expect {
          remote_system_with_sudo
        }.to raise_error(
          Machinery::Errors::InsufficientPrivileges,
          /'sudo' isn't configured on the inspected host/
        )
      end

      it "raises an exception if a tty is required" do
        expect(Machinery::LoggedCheetah).to receive(:run).with(
          "ssh", any_args
        ).and_raise(
          Cheetah::ExecutionFailed.new(
            nil, double(exitstatus: 1), "", "sudo: sorry, you must have a tty to run sudo"
          )
        )

        expect {
          remote_system_with_sudo
        }.to raise_error(
          Machinery::Errors::SudoMissingTTY,
          /Remove the 'requiretty' settings from \/etc\/sudoers by running `visudo`\./
        )
      end

      it "raises an exception if user has no password-less sudo rights" do
        expect(Machinery::LoggedCheetah).to receive(:run).with(
          "ssh", any_args
        ).and_raise(
          Cheetah::ExecutionFailed.new(
            nil, double(exitstatus: 1), "", "sudo: no tty present and no askpass program specified"
          )
        )

        expect {
          remote_system_with_sudo
        }.to raise_error(
          Machinery::Errors::SudoPasswordRequired,
          /Make sure that you have the following line in/
        )
      end
    end

    context "when an ssh port is given" do
      let(:options) { { ssh_port: 5000 } }

      it "builds a correct command line" do
        expect(Cheetah).to receive(:run).with(
          "ssh", "-p", "5000", any_args
        )

        remote_system
      end
    end

    context "when an ssh key is given" do
      let(:options) { { ssh_identity_file: "/tmp/private_ssh_key" } }

      it "builds a correct command line" do
        expect(Cheetah).to receive(:run).with(
          "ssh", "-i", "/tmp/private_ssh_key", any_args
        )

        remote_system
      end
    end
  end

  context "connecting to a remote system" do
    before(:each) do
      allow_any_instance_of(Machinery::RemoteSystem).to receive(:connect)
    end

    describe "#requires_root?" do
      it "returns false" do
        expect(remote_system.requires_root?).to be(false)
      end
    end

    describe "#run_command" do
      context "when ssh connection is disrupted" do
        ["Connection refused", "Broken pipe", "Connection reset by peer", "Network is unreachable"].each do |error|
          it "raises an error" do
            expect(Cheetah).to receive(:run).with(
              "ssh", any_args
            ).and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, error))

            expect { remote_system.run_command("test") }.to raise_error(Machinery::Errors::SshConnectionDisrupted, /#{error}/)
          end
        end
      end

      it "executes commands via ssh" do
        expect(Cheetah).to receive(:run).with(
          "ssh", any_args, "ls", "/tmp", {}
        )

        remote_system.run_command("ls", "/tmp")
      end

      it "executes piped commands via ssh" do
        expect(Cheetah).to receive(:run).with(
          "ssh", any_args, "ls", "/tmp", "|", "grep", "foo",
            "|", "wc", "-l", {}
        )

        remote_system.run_command(["ls", "/tmp"], ["grep", "foo"], ["wc", "-l"])
      end

      it "logs commands by default" do
        expect(Machinery::LoggedCheetah).to receive(:run)

        remote_system.run_command("ls")
      end

      it "does not log commands when :disable_logging is set" do
        expect(Machinery::LoggedCheetah).to_not receive(:run)
        expect(Cheetah).to receive(:run)

        remote_system.run_command("ls", disable_logging: true)
      end

      context "when accessing as a remote user" do
        let(:options) { { remote_user: "machinery" } }

        it "builds a correct command line" do
          expect(Cheetah).to receive(:run).with(
            "ssh", "machinery@remotehost", any_args, "ls", "/tmp", {}
          )

          remote_system.run_command("ls", "/tmp")
        end

        it "uses sudo when necessary" do
          expect(Cheetah).to receive(:run).with(
            "ssh", any_args, "sudo", "-n", "LANGUAGE=", "LC_ALL=C", "ls", "/tmp", privileged: true
          )

          remote_system.run_command("ls", "/tmp", privileged: true)
        end
      end

      context "when running a command with a different ssh port" do
        let(:options) { { ssh_port: 5000 } }

        it "builds a correct command line" do
          expect(Cheetah).to receive(:run).with(
            "ssh", "-p", "5000", any_args, privileged: true
          )

          remote_system.run_command("ls", "/tmp", privileged: true)
        end
      end

      context "when running a command with an ssh key" do
        let(:options) { { ssh_identity_file: "/tmp/private_ssh_key" } }

        it "builds a correct command line" do
          expect(Cheetah).to receive(:run).with(
            "ssh", "-i", "/tmp/private_ssh_key", any_args, privileged: true
          )

          remote_system.run_command("ls", "/tmp", privileged: true)
        end
      end
    end

    describe "#check_retrieve_files_dependencies" do
      it "checks for the availabilty of rsync on the local system" do
        expect(Machinery::LocalSystem).to receive(:validate_existence_of_command).with(
          "rsync", "rsync"
        )
        remote_system.check_retrieve_files_dependencies
      end

      it "checks for the availabilty of rsync on the remote system" do
        allow(Machinery::LocalSystem).to receive(:validate_existence_of_command).with(
          "rsync", "rsync"
        )
        expect(remote_system).to receive(:check_requirement).with(
          "rsync", "--version"
        )
        remote_system.check_retrieve_files_dependencies
      end
    end

    describe "#retrieve_files" do
      context "when retrieving files via rsync" do
        it "builds the correct command" do
          expect(Cheetah).to receive(:run).with(
            "rsync", "-e", "ssh", "--chmod=go-rwx", "--files-from=-", "--rsync-path=rsync",
            "root@remotehost:/", "/tmp",
            stdout: :capture,
            stdin: "/foo\n/bar"
          )

          remote_system.retrieve_files(["/foo", "/bar"], "/tmp")
        end
      end

      context "when retrieving files via sudo rsync" do
        let(:options) { { remote_user: "machinery" } }

        it "adds sudo to the rsync path" do
          expect(Cheetah).to receive(:run) do |*args|
            expect(args).to include("--rsync-path=sudo -n rsync")
          end

          remote_system.retrieve_files(["/foo", "/bar"], "/tmp")
        end
      end

      context "when retrieving files by using a different ssh port" do
        let(:options) { { ssh_port: 5000 } }

        it "builds a correct command line" do
          expect(Cheetah).to receive(:run).with(
            "rsync", "-e", "ssh -p 5000", "--chmod=go-rwx", "--files-from=-", "--rsync-path=rsync",
            "root@remotehost:/", "/tmp",
            stdout: :capture,
            stdin: "/foo\n/bar"
          )

          remote_system.retrieve_files(["/foo", "/bar"], "/tmp")
        end
      end

      context "when retrieving files by using an ssh key" do
        let(:options) { { ssh_identity_file: "/tmp/private_ssh_key" } }

        it "builds a correct command line" do
          expect(Cheetah).to receive(:run).with(
            "rsync", "-e", "ssh -i /tmp/private_ssh_key", "--chmod=go-rwx", "--files-from=-",
            "--rsync-path=rsync",
            "root@remotehost:/", "/tmp",
            stdout: :capture,
            stdin: "/foo\n/bar"
          )

          remote_system.retrieve_files(["/foo", "/bar"], "/tmp")
        end
      end
    end

    describe "#read_file" do
      it "retrieves files in unprivileged mode by default" do
        expect(remote_system).to receive(:run_command).with(
          "cat", "/foo", stdout: :capture, privileged: false
        )
        remote_system.read_file("/foo")
      end

      it "retrieves files with privileged mode" do
        expect(remote_system).to receive(:run_command).with(
          "cat", "/foo", stdout: :capture, privileged: true
        )
        remote_system.read_file("/foo", privileged: true)
      end

      it "retrieves the content of the remote file" do
        expect(remote_system).to receive(:run_command).and_return("foo")
        expect(remote_system.read_file("/foo")).to eq("foo")
      end

      it "returns nil when the file does not exist" do
        status = double(exitstatus: 1)
        expect(remote_system).to receive(:run_command).and_raise(
          Cheetah::ExecutionFailed.new(
            nil, status, nil, nil
          )
        )

        expect(remote_system.read_file("/foo")).to be_nil
      end
    end

    describe "#inject_file" do
      it "builds a correct command line" do
        expect(Cheetah).to receive(:run).with("scp", "/usr/foobar", "root@remotehost:/tmp")
        remote_system.inject_file("/usr/foobar", "/tmp")
      end

      context "when copying a file via scp by using a different ssh port" do
        let(:options) { { ssh_port: 5000 } }

        it "builds a correct command line" do
          expect(Cheetah).to receive(:run).with("scp", "-P", "5000", any_args)
          remote_system.inject_file("/usr/foobar", "/tmp")
        end
      end

      context "when copying a file via scp by using an SSH key" do
        let(:options) { { ssh_identity_file: "/tmp/private_ssh_key" } }

        it "builds a correct command line" do
          expect(Cheetah).to receive(:run).with("scp", "-i", "/tmp/private_ssh_key", any_args)
          remote_system.inject_file("/usr/foobar", "/tmp")
        end
      end
    end

    describe "#remove_file" do
      it "removes a file" do
        expect(remote_system).to receive(:run_command).with(
          "rm", "/tmp/foo"
        )
        remote_system.remove_file("/tmp/foo")
      end
    end
  end
end
