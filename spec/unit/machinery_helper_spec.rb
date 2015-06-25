require_relative "spec_helper"

include GivenFilesystemSpecHelpers

describe MachineryHelper do
  use_given_filesystem

  before(:each) do
    allow_any_instance_of(OsInspector).to receive(:inspect) do |instance|
      json = <<-EOT
        {
          "os": {
            "architecture": "x86_64"
          }
        }
      EOT
      system_description = create_test_description(json: json)
      instance.description.os = system_description.os
    end
  end

  describe "#can_help?" do
    it "can help if helper exists" do
      dummy_system = double
      helper = MachineryHelper.new(dummy_system)
      helper.local_helpers_path = File.join(Machinery::ROOT, "spec/data/machinery_helper")

      expect(helper.can_help?).to be(true)
    end

    it "can not help if helper does not exist" do
      dummy_system = double
      helper = MachineryHelper.new(dummy_system)
      helper.local_helpers_path = given_directory

      expect(helper.can_help?).to be(false)
    end
  end

  it "#inject_helper" do
    dummy_system = double

    helper = MachineryHelper.new(dummy_system)

    local_helper_path = "ab/cd/x86_64/machinery_helper"
    helper.local_helpers_path = "ab/cd"
    remote_path = "."

    expect(dummy_system).to receive(:inject_file).with(local_helper_path,
      remote_path)

    helper.inject_helper
  end

  it "#remove_helper" do
    dummy_system = double

    helper = MachineryHelper.new(dummy_system)

    expect(dummy_system).to receive(:remove_file).with("./machinery_helper")

    helper.remove_helper
  end

  it "#run_helper" do
    dummy_system = double

    helper = MachineryHelper.new(dummy_system)

    json = <<-EOT
      {
        "unmanaged_files": {
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
      }
    EOT

    expect(dummy_system).to receive(:run_command).with("./machinery_helper",
      stdout: :capture).and_return(json)

    scope = UnmanagedFilesScope.new
    helper.run_helper(scope)

    expect(scope.files.first.name).to eq("/opt/magic/file")
    expect(scope.files.count).to eq(2)
  end
end

describe UnmanagedFilesInspector do
  before(:each) do
    allow_any_instance_of(OsInspector).to receive(:inspect) do |instance|
      json = <<-EOT
        {
          "os": {
            "architecture": "x86_64"
          }
        }
      EOT
      system_description = create_test_description(json: json)
      instance.description.os = system_description.os
    end
  end

  it "runs helper" do
    @system = double
    allow(@system).to receive(:check_requirement)

    description = SystemDescription.new("systemname", SystemDescriptionStore.new)
    inspector = UnmanagedFilesInspector.new(@system, description)

    allow_any_instance_of(MachineryHelper).to receive(:can_help?).and_return(true)
    expect_any_instance_of(MachineryHelper).to receive(:inject_helper)
    expect_any_instance_of(MachineryHelper).to receive(:run_helper)

    inspector.inspect(Filter.from_default_definition("inspect"))
  end
end
