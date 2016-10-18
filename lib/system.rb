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

# System and its subclasses are used to represent systems that are to be
# inspected.
#
# It abstracts common inspection tasks that need to be run, like executing
# commands or running "kiwi --describe". Different implementations, e.g. for
# local or ssh-accessed systems are done in the according subclasses.
class Machinery::System
  abstract_method :requires_root?
  abstract_method :run_command
  abstract_method :kiwi_describe
  abstract_method :retrieve_files
  abstract_method :read_file
  abstract_method :inject_file
  abstract_method :remove_file
  abstract_method :type

  attr_writer :locale

  def self.for(host, opts = {})
    if host && host != "localhost"
      Machinery::RemoteSystem.new(host, opts)
    else
      Machinery::LocalSystem.new
    end
  end

  # checks if the required command can be executed on the target system
  def check_requirement(commands, *args)
    commands = Array(commands)
    commands.each do |command|
      begin
        run_command(command, *args)
        return command
      rescue Cheetah::ExecutionFailed
      end
    end
    raise Machinery::Errors::MissingRequirement.new(
      "Need the '#{commands.join("' or '")}' #{Machinery.pluralize(commands.length, "command")}" \
        " to be available on the inspected system."
    )
  end

  def check_retrieve_files_dependencies
    check_requirement("rsync", "--version")
  end

  def check_create_archive_dependencies
    check_requirement("tar", "--version")
    check_requirement("gzip", "--version")
  end

  # Retrieves files specified in filelist from the remote system and create an archive.
  # To be able to deal with arbitrary filenames we use zero-terminated
  # filelist and the --null option of tar
  def create_archive(file_list, archive, exclude = [])
    Machinery.logger.info(
      "The following files are packaged in #{archive}: " + Array(file_list).join(", ")
    )
    created = !File.exist?(archive)
    out = File.open(archive, "w")
    begin
      run_command(
        "tar", "--create", "--gzip",
        *exclude.flat_map { |f| ["--exclude", f]},
        "--null", "--files-from=-",
        stdout: out,
        stdin: Array(file_list).join("\0"),
        privileged: true,
        disable_logging: true
      )
    rescue Cheetah::ExecutionFailed => e
      if e.status.exitstatus == 1
        # The tarball has been created successfully but some files were changed
        # on disk while being archived, so we just log the warning and go on
        Machinery.logger.info e.stderr
      else
        raise
      end
    end
    out.close
    File.chmod(0600, archive) if created
  end

  def run_script(*args)
    script = File.read(File.join(Machinery::ROOT, "inspect_helpers", args.shift))

    run_command("bash", "-c", script, *args)
  end

  # Runs the given script on the inspected machine asynchronously and calls the callback method
  # periodically with new output when it occurs.
  #
  # Example:
  #
  #     count = 0
  #     raw_list = run_script_with_progress("changed_managed_files.sh") do |chunk|
  #       count += chunk.lines.count
  #       Machinery::Ui.progress("Found #{count} changed files...")
  #     end
  def run_script_with_progress(*script, &callback)
    run_with_progress(*script, :script, &callback)
  end

  def run_command_with_progress(*command, &callback)
    run_with_progress(*command, :command, &callback)
  end

  def has_command?(command)
    run_command("bash", "-c", "type -P #{command}", stdout: :capture)
    true
  rescue Cheetah::ExecutionFailed
    false
  end

  def arch
    run_command("uname", "-m", stdout: :capture).chomp
  end

  def locale
    @locale || "C"
  end

  def managed_files_database
    if @managed_files_database
      return @managed_files_database
    elsif has_command?("rpm")
      @managed_files_database = RpmDatabase.new(self)
    elsif has_command?("dpkg")
      @managed_files_database = DpkgDatabase.new(self)
    else
      raise Machinery::Errors::MissingRequirement.new(
        "Need binary 'rpm' or 'dpkg' to be available on the inspected system."
      )
    end
  end

  private

  def run_with_progress(*command, type, &callback)
    output = ""
    error = ""
    write_io = StringIO.new(output, "a")
    error_io = StringIO.new(error, "a")
    read_io = StringIO.new(output, "r")

    options = command.last.is_a?(Hash) ? command.pop : {}
    options[:stdout] = write_io
    options[:stderr] = error_io

    Thread.abort_on_exception = true
    inspect_thread = Thread.new do
      if type == :script
        run_script(*command, options)
      else
        run_command(*command, options)
      end
    end

    while inspect_thread.alive?
      sleep 0.1
      chunk = read_io.read
      callback.call(chunk) if callback
    end

    output
  rescue
    raise Machinery::Errors::CommandFailed.new(command.join(" "), error)
  end
end
