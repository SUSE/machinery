require_relative "spec_helper"

include GivenFilesystemSpecHelpers

describe MachineryHelper do
  use_given_filesystem

  let(:remote_helper_path) { "/root/machinery-helper" }
  let(:dummy_system) {
    double(
      arch: "x86_64", run_command: remote_helper_path, remote_user: "machinery", host: "host"
    )
  }
  subject { MachineryHelper.new(dummy_system) }

  describe "#can_help?" do
    context "on the same architecture" do
      before(:each) do
        allow(Machinery::LocalSystem).to receive(:validate_architecture)
      end

      it "returns true if helper exists" do
        subject.local_helpers_path = given_directory
        FileUtils.touch(subject.local_helper_path)

        expect(subject.can_help?).to be(true)
      end

      it "returns false if helper does not exist" do
        subject.local_helpers_path = given_directory

        expect(subject.can_help?).to be(false)
      end
    end

    it "returns false if the architectures don't match" do
      subject = MachineryHelper.new(
        double(arch: "unknown_arch", run_command: "/root/machinery-helper")
      )
      subject.local_helpers_path = File.join(Machinery::ROOT, "spec/data/machinery-helper")

      expect(subject.can_help?).to be(false)
    end
  end

  describe "#local_helper_path" do
    it "returns the machinery-helper path for supported system archs" do
      expect(subject.local_helper_path).to eq(
        File.join(Machinery::ROOT, "machinery-helper", "machinery-helper-#{dummy_system.arch}")
      )
    end

    context "in case of old compatible architectures" do
      it "returns the i686 binary for i586 systems" do
        expect(dummy_system).to receive(:arch).and_return("i586")

        expect(subject.local_helper_path).to eq(
          File.join(Machinery::ROOT, "machinery-helper", "machinery-helper-i686")
        )
      end

      it "returns the i686 binary for i386 systems" do
        expect(dummy_system).to receive(:arch).and_return("i386")

        expect(subject.local_helper_path).to eq(
          File.join(Machinery::ROOT, "machinery-helper", "machinery-helper-i686")
        )
      end

      it "returns the armv7l binary for armv6l systems" do
        expect(dummy_system).to receive(:arch).and_return("armv6l")

        expect(subject.local_helper_path).to eq(
          File.join(Machinery::ROOT, "machinery-helper", "machinery-helper-armv7l")
        )
      end
    end
  end

  describe "#inject_helper" do
    it "injects the helper using System#inject_file" do
      expect(dummy_system).to receive(:inject_file)

      subject.inject_helper
    end
  end

  describe "#remove_helper" do
    it "removes the helper using System#remove_file" do
      expect(dummy_system).to receive(:remove_file).with(remote_helper_path)

      subject.remove_helper
    end
  end

  describe "#run_helper" do
    let(:scope) { Machinery::UnmanagedFilesScope.new }
    let(:json) { <<-EOT
        {
          "files": [
            {
              "name": "/opt/magic/file",
              "type": "file",
              "user": "root",
              "group": "root",
              "size": 0,
              "mode": "644"
            },
            {
              "name": "/opt/magic/other_file",
              "type": "file",
              "user": "root",
              "group": "root",
              "size": 0,
              "mode": "644"
            }
          ]
        }
      EOT
    }

    it "writes the inspection result into the scope" do
      expect(dummy_system).to receive(:run_command).with("/root/machinery-helper", any_args).
        and_return(json)

      subject.run_helper(scope)

      expect(scope.first.name).to eq("/opt/magic/file")
      expect(scope.count).to eq(2)
    end

    it "pases the extract metadata option" do
      expect(dummy_system).to receive(:run_command).
        with("/root/machinery-helper", "--extract-metadata", any_args).and_return(json)

      subject.run_helper(scope, "--extract-metadata")
    end

    context "when errors occur" do
      before(:each) do
        expect(dummy_system).to receive(:run_command).with("/root/machinery-helper", any_args).
          and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))
      end

      it "handles sudo password ones gracefully" do
        expect_any_instance_of(TeeIO).to receive(:string).and_return("password is required")
        expect { subject.run_helper(scope) }.to raise_error(
          Machinery::Errors::InsufficientPrivileges, /host/
        )
      end

      it "raises on all other" do
        expect_any_instance_of(TeeIO).to receive(:string).and_return("some random error")
        expect { subject.run_helper(scope) }.to raise_error(
          Cheetah::ExecutionFailed
        )
      end
    end
  end

  describe "#run_helper_subcommand" do
    it "calls run_command with helper path and the parameters" do
      expect(dummy_system).to receive(:run_command).with(
        remote_helper_path, "tar", "--create", stdout: :capture, privileged: true
      )
      subject.run_helper_subcommand("tar", "--create", stdout: :capture)
    end
  end

  describe "#has_compatible_version?" do
    let(:commit_id) { "b5ebdef2ccc0398113e4d88e04083a8369394f12" }
    let(:remote_helper) { "/root/machinery-helper" }

    before(:each) do
      allow(File).to receive(:read).with(
        File.join(Machinery::ROOT, ".git_revision")
      ).and_return(commit_id)
    end

    it "returns true if the machinery version equals the helper version" do
      expect(dummy_system).to receive(:run_command).with(
        remote_helper, "--version", stdout: :capture
      ).and_return("Version: #{commit_id}")
      expect(subject.has_compatible_version?).to be(true)
    end

    it "returns false if the machinery version does not equal the helper version" do
      expect(dummy_system).to receive(:run_command).with(
        remote_helper, "--version", stdout: :capture
      ).and_return("Version: 17c59264b8109ed33bb9bd1371af05bfb81d10df")
      expect(subject.has_compatible_version?).to be(false)
    end

    it "returns false on empty output of an old machinery-helper" do
      expect(dummy_system).to receive(:run_command).with(
        remote_helper, "--version", stdout: :capture
      ).and_return("")
      expect(subject.has_compatible_version?).to be(false)
    end
  end

  describe "#remote_helper_path" do
    let(:path) { "/root/machinery-helper" }

    it "expands the path on the remote machine and returns it" do
      expect(dummy_system).to receive(:run_command).with(
        "bash", "-c", "echo -n #{File.join(Machinery::HELPER_REMOTE_PATH, "machinery-helper")}",
          stdout: :capture
      ).and_return(path)
      expect(subject.remote_helper_path).to eq(path)
    end

    it "stores the result of the first call" do
      expect(dummy_system).to receive(:run_command).once
      subject.remote_helper_path
      subject.remote_helper_path
    end
  end
end
