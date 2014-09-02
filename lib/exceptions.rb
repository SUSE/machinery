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

module Machinery
  module Errors
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

    class BuildFailed < MachineryError; end
    class DeployFailed < MachineryError; end
    class InspectionFailed < MachineryError; end
    class KiwiExportFailed < MachineryError; end

    class SshConnectionFailed < MachineryError; end
    class RsyncFailed < MachineryError; end
  end
end
