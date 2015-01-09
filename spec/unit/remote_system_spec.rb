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
         "ssh", "-q", "-o", "BatchMode=yes", "root@example.com"
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
        expect(Cheetah).to receive(:run).with("ssh", "root@remotehost", "LC_ALL=C", "ls", "/tmp", {})

        remote_system.run_command("ls", "/tmp")
      end

      it "executes piped commands via ssh" do
        expect(Cheetah).to receive(:run).with("ssh", "root@remotehost", "LC_ALL=C", "ls", "/tmp", "|", "grep", "foo", "|", "wc", "-l", {})

        remote_system.run_command(["ls", "/tmp"], ["grep", "foo"], ["wc", "-l"])
      end

      it "logs commands by default" do
        expect(LoggedCheetah).to receive(:run)

        remote_system.run_command("ls")
      end

      it "does not log commands when :disable_logging is set" do
        expect(LoggedCheetah).to_not receive(:run)
        expect(Cheetah).to receive(:run)

        remote_system.run_command("ls", :disable_logging => true)
      end
    end

    describe "#retrieve_files" do
      it "retrieves files via rsync from a remote host" do
        expect(Cheetah).to receive(:run).with("rsync", "-e", "ssh", "--chmod=go-rwx", "--files-from=-", "root@remotehost:/", "/tmp",  :stdout => :capture, :stdin => "/foo\n/bar" )

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
  end
end
