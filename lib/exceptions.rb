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

module Machinery
  module Errors
    class IncompatibleHost < StandardError; end

    # Superclass for all "expected" errors in Machinery.
    # "Expected" errors are errors which are caused by the environment or input
    # data and are not caused by bugs in the machinery codebase.
    #
    # Those errors will be handled specially by the machinery tool, e.g. by not
    # showing a backtrace.
    class MachineryError < StandardError; end

    class UnknownScope < MachineryError; end
    class UnknownOs < MachineryError
      def to_s
        "Unable to determine the operating system. There does not seem to be an" \
          " /etc/os-release file."
      end
    end
    class InvalidPager < MachineryError; end
    class InvalidCommandLine < MachineryError; end

    class MissingRequirement < MachineryError; end

    class SystemDescriptionError < MachineryError; end
    class SystemDescriptionNotFound < SystemDescriptionError; end

    class SystemDescriptionIncompatible < SystemDescriptionError
      attr_reader :name, :format_version

      def initialize(name, format_version)
        @name = name
        @format_version = format_version
      end

      def to_s
        if !@format_version
          "#{@name}: incompatible format version. Can not be upgraded."
        elsif @format_version < SystemDescription::CURRENT_FORMAT_VERSION
          "#{@name}: format version #{@format_version}, needs to be upgraded. "\
          "Try '#{Ui::Hint.program_name} upgrade-format #{name}'"\
          " to upgrade it to the current version."
        else
          "#{@name}: format version #{@format_version}. " \
            "Please upgrade Machinery to the latest version."
        end
      end
    end

    class MissingExtractedFiles < SystemDescriptionError
      def initialize(description, scopes)
        @description = description
        @scopes = scopes
      end

      def to_s
        hostname = @scopes.map do |s|
          @description[s].meta.hostname if @description[s].meta
        end.compact.first || "<HOSTNAME>"
        formatted_scopes = Machinery::Ui.internal_scope_list_to_string(@scopes)

        if @description["environment"]["system_type"] == "docker"
          inspect_cmd = "inspect-container"
        else
          inspect_cmd = "inspect"
        end

        cmd = "#{Ui::Hint.program_name} #{inspect_cmd} --extract-files " \
          "--scope=#{formatted_scopes.delete(" ")}"
        cmd += " --name='#{@description.name}'" if hostname != @description.name
        cmd += " #{hostname}"

        if @scopes.count > 1
          output = "The following scopes '#{formatted_scopes}' are part of the system description"
        else
          output = "The scope '#{formatted_scopes}' is part of the system description"
        end
        output += " but the corresponding files weren't extracted during inspection.\n" \
        "The files are required to continue with this command." \
        " Run `#{cmd}` to extract them."
      end
    end

    class SystemDescriptionValidationFailed < SystemDescriptionError
      attr_reader :errors
      attr_accessor :header

      def initialize(errors)
        @errors = errors
      end

      def to_s
        message = ""
        if @header
          message += header + "\n\n"
        end
        message += @errors.join("\n")
        message += "\n"
        message
      end
    end

    class InsufficientPrivileges < MachineryError
      def initialize(remote_user, host)
        @remote_user = remote_user
        @host = host
      end

      def to_s
        "'sudo' isn't configured on the inspected host '#{@host}' for user '#{@remote_user}' to " \
        "give all required commands enough privileges. See 'PREREQUISITES' section in the " \
        "machinery documentation for a description on how to configure sudo on the inspected host."
      end
    end

    class CommandFailed < MachineryError
      def initialize(command, error)
        @command = command
        @error = error
      end

      def to_s
        "The required call '#{@command}' does not seem to work as expected on the" \
          " inspected system. This is the error message:\n#{@error}"
      end
    end

    class SudoMissingTTY < MachineryError
      def initialize(host)
        @host = host
      end

      def to_s
        "'sudo' isn't configured on the inspected host '#{@host}'." \
        " Remove the 'requiretty' settings from /etc/sudoers by running `visudo`."
      end
    end

    # An error for inspecting a remote system as a non-root user
    class SudoPasswordRequired < MachineryError
      def initialize(host)
        @host = host
      end

      def to_s
        "`sudo` can be used only on #{@host}, when no password is required." \
        " Make sure that you have the following line in `etc/sudoers` on the remote host:\n" \
        " machinery ALL=(ALL) NOPASSWD: ALL"
      end
    end

    class MigrationError < MachineryError; end

    class InvalidFilter < MachineryError; end
    class ElementFilterTypeMismatch < MachineryError
      attr_accessor :failed_matcher
    end
    class FileUtilsError < MachineryError; end

    class BuildFailed < MachineryError; end
    class DeployFailed < MachineryError; end
    class InspectionFailed < MachineryError; end
    class ExportFailed < MachineryError; end
    class AnalysisFailed < MachineryError; end
    class UpgradeFailed < MachineryError; end
    class BinaryDiffError < MachineryError; end

    class SshConnectionFailed < MachineryError; end
    class SshConnectionDisrupted < MachineryError; end
    class RsyncFailed < MachineryError; end
    class WrongFilterPath < MachineryError; end
    class OpenInBrowserFailed < MachineryError; end
    class ZypperFailed < MachineryError; end
    class UnknownConfig < MachineryError; end
    class UnsupportedArchitecture < MachineryError; end
    class ServeFailed < MachineryError; end
    class RemoveFileFailed < MachineryError; end
    class InjectFileFailed < MachineryError; end
    class UnexpectedInputData < MachineryError; end
    class ComposeServiceLink < MachineryError; end
    class UnsupportedHelperVersion < MachineryError; end
    class ServerPortError < MachineryError
      attr_reader :message

      def initialize(message)
        @message = message
      end
    end
    class BuildDirectoryCreateError < MachineryError
      def initialize(directory, user)
        @directory = directory
        @user = user
      end

      def to_s
        "Could not create build directory '#{@directory}' because the user '#{@user}' does not " \
          "have sufficient permissions."
      end
    end
  end
end
