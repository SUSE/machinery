class MachineryHelper
  attr_accessor :local_helpers_path

  def initialize(s)
    @system = s
    @arch = nil

    @local_helpers_path = "/usr/share/machinery/helpers"
  end

  def local_helper_path
    if !@arch
      description = SystemDescription.new("", SystemDescriptionMemoryStore.new)
      inspector = OsInspector.new(@system, description)
      inspector.inspect(nil)

      @arch = description.os.architecture
    end

    File.join(@local_helpers_path, @arch, "machinery_helper")
  end

  # Returns true, if there is a helper binary matching the architecture of the
  # inspected system. Return false, if not.
  def can_help?
    File.exist?(local_helper_path)
  end

  def inject_helper
    @system.inject_file(local_helper_path, ".")
  end

  def run_helper(scope)
    json = @system.run_command("./machinery_helper", stdout: :capture)
    scope.set_attributes(JSON.parse(json)["unmanaged_files"])
  end

  def remove_helper
    @system.remove_file("./machinery_helper")
  end
end
