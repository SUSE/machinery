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
    class UnknownOs < MachineryError; end
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
        "The system description '#{@name}' has an incompatible data " \
        "format and can not be read.\n" \
        "Try '#{Hint.program_name} upgrade-format #{name}' to upgrade it to the current version.\n"
      end
    end

    class MissingExtractedFiles < SystemDescriptionError
      def initialize(description, scopes)
        @description = description
        @scopes = scopes
      end

      def to_s
        meta = @description[@scopes.first].meta
        hostname = @scopes.map do |s|
          @description[s].meta.hostname if @description[s].meta
        end.compact.first || "<HOSTNAME>"
        formatted_scopes = Machinery::Ui.internal_scope_list_to_string(@scopes)

        cmd = "#{Hint.program_name} inspect --extract-files --scope=#{formatted_scopes.delete(" ")}"
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
        "sudo isn't configured on the inspected host '#{@host}' for user '#{@remote_user}' to " \
        "give all required commands enough privileges. See 'PREREQUISITES' section in the " \
        "machinery man page for a description on how to configure sudo on the inspected host."
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
    class RsyncFailed < MachineryError; end
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
  end
end
