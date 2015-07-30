require_relative "spec_helper"

include GivenFilesystemSpecHelpers

describe MachineryHelper do
  use_given_filesystem

  let(:dummy_system) { double(arch: "x86_64") }

  describe "#can_help?" do
    it "can help if helper exists" do
      helper = MachineryHelper.new(dummy_system)
      helper.local_helpers_path = File.join(Machinery::ROOT, "spec/data/machinery-helper")

      expect(helper.can_help?).to be(true)
    end

    it "can not help if helper does not exist" do
      helper = MachineryHelper.new(dummy_system)
      helper.local_helpers_path = given_directory

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

      expect(dummy_system).to receive(:remove_file).with("./machinery-helper")

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

      expect(dummy_system).to receive(:run_command).with("./machinery-helper", any_args).
        and_return(json)

      scope = UnmanagedFilesScope.new
      helper.run_helper(scope)

      expect(scope.files.first.name).to eq("/opt/magic/file")
      expect(scope.files.count).to eq(2)
    end
  end
end
