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

class RemoteSystem < System
  attr_accessor :host
  attr_accessor :remote_user

  def initialize(host, remote_user = "root")
    @host = host
    @remote_user = remote_user

    connect
  end

  def requires_root?
    false
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
      cheetah_class = LoggedCheetah
    end

    sudo = "sudo" if options[:privileged] && remote_user != "root"
    cmds = ["ssh", "#{remote_user}@#{host}", sudo, "LC_ALL=C", *piped_args, options].compact
    cheetah_class.run(*cmds)
  end

  # Tries to connect to the remote system as root (without a password or passphrase)
  # and raises an Machinery::Errors::SshConnectionFailed exception when it's not successful.
  def connect
    LoggedCheetah.run "ssh", "-q", "-o", "BatchMode=yes", "#{remote_user}@#{host}"
  rescue Cheetah::ExecutionFailed
    raise Machinery::Errors::SshConnectionFailed.new(
      "Could not establish SSH connection to host '#{host}'. Please make sure that " \
      "you can connect non-interactively as #{remote_user}, e.g. using ssh-agent.\n\n" \
      "To copy your default ssh key to the machine run:\n" \
      "ssh-copy-id #{remote_user}@#{host}"
    )
  end


  # Retrieves files specified in filelist from the remote system and raises an
  # Machinery::Errors::RsyncFailed exception when it's not successful. Destination is
  # the directory where to put the files.
  def retrieve_files(filelist, destination)
    source = "#{remote_user}@#{host}:/"
    if remote_user != "root"
      rsync_path = "sudo rsync"
    else
      rsync_path = "rsync"
    end

    cmd = [
      "rsync",
      "-e", "ssh",
      "--chmod=go-rwx",
      "--files-from=-",
      "--rsync-path=#{rsync_path}",
      source,
      destination,
      stdout: :capture,
      stdin: filelist.join("\n")
    ]
    begin
      LoggedCheetah.run(*cmd)
    rescue Cheetah::ExecutionFailed  => e
      raise Machinery::Errors::RsyncFailed.new(
      "Could not rsync files from host '#{host}'.\n" \
      "Error: #{e}"
    )
    end
  end

  # Reads a file from the System. Returns nil if it does not exist.
  def read_file(file)
    run_command("cat", file, stdout: :capture, privileged: true)
  rescue Cheetah::ExecutionFailed => e
    if e.status.exitstatus == 1
      # File not found, return nil
      return
    else
      raise
    end
  end
end
