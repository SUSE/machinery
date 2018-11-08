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

class Machinery::RemoteSystem < Machinery::System
  attr_reader :host, :remote_user, :ssh_port, :ssh_identity_file

  def type
    "remote"
  end

  def initialize(host, opts = {})
    options = {
      remote_user: "root",
      ssh_port: nil,
      ssh_identity_file: nil
    }.merge(opts)

    @host = host
    @remote_user = options[:remote_user]
    @ssh_port = options[:ssh_port]
    @ssh_identity_file = options[:ssh_identity_file]

    connect
  end

  def requires_root?
    false
  end

  def connect
    check_connection
    check_sudo if sudo_required?
  end

  def run_command(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}

    # There are three valid ways how to call Cheetah.run, whose interface this
    # method mimics. The following code ensures that the "commands" variable
    # consistently (in all three cases) contains an array of arrays specifying
    # commands and their arguments.
    #
    # See comment in Cheetah.build_commands for more detailed explanation:
    #
    #   https://github.com/openSUSE/cheetah/blob/0cd3f88c1210305e87dfc4852bb83040e82d783f/lib/cheetah.rb#L395
    #
    commands = args.all? { |a| a.is_a?(Array) } ? args : [args]

    # When ssh executes commands, it passes them through shell expansion. For
    # example, compare
    #
    #   $ echo '$HOME'
    #   $HOME
    #
    # with
    #
    #   $ ssh localhost echo '$HOME'
    #   /home/dmajda
    #
    # To mitigate that and maintain usual Cheetah semantics, we need to protect
    # the command and its arguments using another layer of escaping.
    escaped_commands = commands.map do |command|
      command.map { |c| Shellwords.escape(c) }
    end

    # Arrange the commands in a way that allows piped commands trough ssh.
    piped_args = escaped_commands[0..-2].flat_map do |command|
      [*command, "|"]
    end + escaped_commands.last

    if options[:disable_logging]
      cheetah_class = Cheetah
    else
      cheetah_class = Machinery::LoggedCheetah
    end

    sudo = ["sudo", "-n"] if options[:privileged] && sudo_required?
    cmds = [
      *build_command(:ssh), "#{remote_user}@#{host}", "-o", \
      "LogLevel=ERROR", sudo, "LANGUAGE=", "LC_ALL=#{locale}", *piped_args, options
    ].compact.flatten

    begin
      cheetah_class.run(*cmds)
    rescue Cheetah::ExecutionFailed => e
      ssh_error_regex = /Connection refused|Connection reset by peer|Broken pipe|Network is unreachable/
      if e.stderr && e.stderr =~ ssh_error_regex
        raise Machinery::Errors::SshConnectionDisrupted.new("\nSSH ERROR: #{e.stderr}")
      else
        raise
      end
    end
  end

  # Retrieves files specified in filelist from the remote system and raises an
  # Machinery::Errors::RsyncFailed exception when it's not successful. Destination is
  # the directory where to put the files.
  def retrieve_files(filelist, destination)
    source = "#{remote_user}@#{host}:/"
    rsync_path = if sudo_required?
      "sudo -n rsync"
    else
      "rsync"
    end

    cmd = [
      "rsync",
      "-e", build_command(:ssh).join(" "),
      "--chmod=go-rwx",
      "--files-from=-",
      "--rsync-path=#{rsync_path}",
      source,
      destination,
      stdout: :capture,
      stdin: filelist.join("\n")
    ]
    begin
      Machinery::LoggedCheetah.run(*cmd)
    rescue Cheetah::ExecutionFailed  => e
      raise Machinery::Errors::RsyncFailed.new(
      "Could not rsync files from host '#{host}'.\n" \
      "Error: #{e}"
    )
    end
  end

  def check_retrieve_files_dependencies
    Machinery::LocalSystem.validate_existence_of_command("rsync", "rsync")
    check_requirement("rsync", "--version")
  end

  # Reads a file from the System. Returns nil if it does not exist.
  def read_file(file, options = {})
    command_options = {
      stdout: :capture,
      privileged: options.fetch(:privileged, false)
    }
    run_command("cat", file, command_options)
  rescue Cheetah::ExecutionFailed => e
    if e.status.exitstatus == 1
      # File not found, return nil
      return
    else
      raise
    end
  end

  # Copies a file to the system
  def inject_file(source, destination)
    destination = "#{remote_user}@#{host}:#{destination}"

    cmd = [
      *build_command(:scp),
      source,
      destination
    ]

    begin
      Machinery::LoggedCheetah.run(*cmd)
    rescue Cheetah::ExecutionFailed => e
      raise Machinery::Errors::InjectFileFailed.new(
        "Could not inject file '#{source}' to host '#{host}'.\nError: #{e}"
      )
    end
  end

  # Removes a file from the system
  def remove_file(file)
    run_command("rm", file)
  rescue Cheetah::ExecutionFailed => e
    raise Machinery::Errors::RemoveFileFailed.new(
      "Could not remove file '#{file}' on host '#{host}'.\nError: #{e}"
    )
  end

  private

  def sudo_required?
    remote_user != "root"
  end

  # Tries to run the noop-command(:) on the remote system as root (without a password or passphrase)
  # and raises an Machinery::Errors::SshConnectionFailed exception when it's not successful.
  def check_connection
    Machinery::LoggedCheetah.run(*build_command(:ssh), "-q", "-o", "BatchMode=yes",
      "#{remote_user}@#{host}", "LC_ALL=#{locale}", ":")
  rescue Cheetah::ExecutionFailed
    raise Machinery::Errors::SshConnectionFailed.new(
      "Could not establish SSH connection to host '#{host}'. Please make sure that " \
      "you can connect non-interactively as #{remote_user}, e.g. using ssh-agent.\n\n" \
      "To copy your default ssh key to the machine run:\n" \
      "ssh-copy-id #{remote_user}@#{host}"
    )
  end

  def check_sudo
    check_requirement("sudo", "-h")
    Machinery::LoggedCheetah.run(*build_command(:ssh), "-q", "-o", "BatchMode=yes",
      "#{remote_user}@#{host}", "LC_ALL=#{locale}", "sudo", "id")
  rescue Cheetah::ExecutionFailed => e
    if e.stderr && e.stderr.include?("password is required")
      raise Machinery::Errors::InsufficientPrivileges.new(remote_user, host)
    elsif e.stderr && e.stderr.include?("you must have a tty to run sudo")
      raise Machinery::Errors::SudoMissingTTY.new(host)
    elsif e.stderr && e.stderr.include?("no tty present and no askpass program specified")
      raise Machinery::Errors::SudoPasswordRequired.new(host)
    else
      raise e
    end
  end

  def build_command(name)
    raise Machinery::Errors::MachineryError.new("You must set one of these flags in " \
      "build_command: :ssh or :scp") unless [:ssh, :scp].include?(name)

    command = [name.to_s]

    if name == :ssh && @ssh_port
      command.push("-p")
      command.push(@ssh_port.to_s)
    elsif name == :scp && @ssh_port
      command.push("-P")
      command.push(@ssh_port.to_s)
    end

    if @ssh_identity_file
      command.push("-i")
      command.push(@ssh_identity_file)
    end

    command
  end
end
