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

class LocalSystem < System
  @@os = nil

  class << self
    def os
      if !@@os
        description = SystemDescription.new("localhost",
          SystemDescriptionMemoryStore.new)
        inspector = OsInspector.new
        inspector.inspect(System.for("localhost"), description)
        @@os = description.os
      end
      @@os
    end

    def validate_existence_of_package(package)
      begin
        Cheetah.run("rpm", "-q", package)
      rescue
        needed_module = os.module_required_by_package(package)
        if needed_module
          raise(Machinery::Errors::MissingRequirement.new("You need the package '#{package}' from module '#{needed_module}'. You can install it as follows:\n" \
            "If you haven't selected the module '#{needed_module}' before, run `yast2 scc` and choose 'Select Extensions' and activate '#{needed_module}'.\nRun `zypper install #{package}` to install the package."))
        else
          raise(Machinery::Errors::MissingRequirement.new("You need the package '#{package}'. You can install it by running `zypper install #{package}`"))
        end
      end
    end

    def validate_machinery_compatibility
      if !os.can_run_machinery?
        supported_oses = Os.supported_host_systems.map { |o| o.canonical_name }.
          sort.join(", ")
        message = "Running Machinery is not supported on this system.\n" \
          "Supported operating systems are: #{supported_oses}"

        raise(Machinery::Errors::IncompatibleHost.new(message))
      end
    end

    def validate_build_compatibility(system_description)
      if !os.can_build?(system_description.os)
        message = "Building '#{system_description.os.canonical_name}' images is " \
          "not supported on this distribution.\n" \
          "Check the 'BUILD SUPPORT MATRIX' section in our man page for " \
          "further information which build targets are supported."

        raise(Machinery::Errors::BuildFailed.new(message))
      end
    end

    def validate_architecture(arch)
      if os.architecture != arch
        raise(Machinery::Errors::IncompatibleHost.new(
          "This operation is not supported on architecture '#{os.architecture}'."
        ))
      end
    end
  end

  def requires_root?
    true
  end

  def run_command(*args)
    if args.last.is_a?(Hash) && args.last[:disable_logging]
      cheetah_class = Cheetah
    else
      cheetah_class = LoggedCheetah
    end
    with_c_locale do
      cheetah_class.run(*args)
    end
  end

  # Retrieves files specified in filelist from the local system and raises an
  # Machinery::Errors::RsyncFailed exception when it's not successful. Destination is
  # the directory where to put the files.
  def retrieve_files(filelist, destination)
    begin
      LoggedCheetah.run("rsync",  "--chmod=go-rwx", "--files-from=-", "/", destination, :stdout => :capture, :stdin => filelist.join("\n") )
    rescue Cheetah::ExecutionFailed => e
      raise Machinery::Errors::RsyncFailed.new(
      "Could not rsync files from localhost. \n" \
      "Error: #{e}\n" \
      "If you lack read permissions on some files you may want to retry as user root or specify\n" \
      "the fully qualified host name instead of localhost in order to connect as root via ssh."
    )
    end
  end

  # Reads a file from the System. Returns nil if it does not exist.
  def read_file(file)
    File.read(file)
  rescue Errno::ENOENT
    # File not found, return nil
    return
  end
end
