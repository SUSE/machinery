require_relative "spec_helper"

include GivenFilesystemSpecHelpers

describe MachineryHelper do
  use_given_filesystem

  let(:remote_helper_path) { "/root/machinery-helper" }
  let(:dummy_system) { double(arch: "x86_64", run_command: remote_helper_path) }

  describe "#can_help?" do
    context "on the same architecture" do
      before(:each) do
        allow(LocalSystem).to receive(:validate_architecture)
      end

      it "returns true if helper exists" do
        helper = MachineryHelper.new(dummy_system)
        helper.local_helpers_path = File.join(Machinery::ROOT, "spec/data/machinery-helper")

        expect(helper.can_help?).to be(true)
      end

      it "returns false if helper does not exist" do
        helper = MachineryHelper.new(dummy_system)
        helper.local_helpers_path = given_directory

        expect(helper.can_help?).to be(false)
      end
    end

    it "returns false if the architectures don't match" do
      helper = MachineryHelper.new(
        double(arch: "unknown_arch", run_command: "/root/machinery-helper")
      )
      helper.local_helpers_path = File.join(Machinery::ROOT, "spec/data/machinery-helper")

      expect(helper.can_help?).to be(false)
    end
  end

  describe "#inject_helper" do
    it "injects the helper using System#inject_file" do
      helper = MachineryHelper.new(dummy_system)
      expect(dummy_system).to receive(:inject_file)

      helper.inject_helper
    end
  end

  describe "#remove_helper" do
    it "removes the helper using System#remove_file" do
      helper = MachineryHelper.new(dummy_system)

      expect(dummy_system).to receive(:remove_file).with(remote_helper_path)

      helper.remove_helper
    end
  end

  describe "#run_helper" do
    it "writes the inspection result into the scope" do
      helper = MachineryHelper.new(dummy_system)

      json = <<-EOT
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

      expect(dummy_system).to receive(:run_command).with("/root/machinery-helper", any_args).
        and_return(json)

      scope = UnmanagedFilesScope.new
      helper.run_helper(scope)

      expect(scope.first.name).to eq("/opt/magic/file")
      expect(scope.count).to eq(2)
    end
  end

  describe "#run_helper_subcommand" do
    it "calls run_command with helper path and the parameters" do
      helper = MachineryHelper.new(dummy_system)
      expect(dummy_system).to receive(:run_command).with(
        remote_helper_path, "tar", "--create", stdout: :capture, privileged: true
      )
      helper.run_helper_subcommand("tar", "--create", stdout: :capture)
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
      helper = MachineryHelper.new(dummy_system)
      expect(dummy_system).to receive(:run_command).with(
        remote_helper, "--version", stdout: :capture
      ).and_return("Version: #{commit_id}")
      expect(helper.has_compatible_version?).to be(true)
    end

    it "returns false if the machinery version does not equal the helper version" do
      helper = MachineryHelper.new(dummy_system)
      expect(dummy_system).to receive(:run_command).with(
        remote_helper, "--version", stdout: :capture
      ).and_return("Version: 17c59264b8109ed33bb9bd1371af05bfb81d10df")
      expect(helper.has_compatible_version?).to be(false)
    end

    it "returns false on empty output of an old machinery-helper" do
      helper = MachineryHelper.new(dummy_system)
      expect(dummy_system).to receive(:run_command).with(
        remote_helper, "--version", stdout: :capture
      ).and_return("")
      expect(helper.has_compatible_version?).to be(false)
    end
  end

  describe "#remote_helper_path" do
    let(:path) { "/root/machinery-helper" }

    it "expands the path on the remote machine and returns it" do
      helper = MachineryHelper.new(dummy_system)
      expect(dummy_system).to receive(:run_command).with(
        "bash", "-c", "echo -n #{File.join(Machinery::HELPER_REMOTE_PATH, "machinery-helper")}",
          stdout: :capture
      ).and_return(path)
      expect(helper.remote_helper_path).to eq(path)
    end

    it "stores the result of the first call" do
      helper = MachineryHelper.new(dummy_system)
      expect(dummy_system).to receive(:run_command).once
      helper.remote_helper_path
      helper.remote_helper_path
    end
  end
end
