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

    class SystemDescriptionValidationFailed < MachineryError; end
    class SystemDescriptionNotFound < MachineryError; end
    class SystemDescriptionAlreadyExists < MachineryError; end
    class SystemDescriptionIncomplete < MachineryError; end
    class SystemDescriptionNameInvalid < MachineryError; end
    class SystemDescriptionInvalid < MachineryError; end

    class UnknownInspector < MachineryError; end
    class UnknownRenderer < MachineryError; end
    class ScopeFailed < MachineryError; end

    class MissingSystemRequirement < MachineryError; end
    class UnsupportedOperatingSystem < MachineryError; end
    class MissingRequirement < MachineryError; end

    class BuildFailed < MachineryError; end
    class UnsupportedBuildTarget < MachineryError; end

    class SshConnectionFailed < MachineryError; end
    class RsyncFailed < MachineryError; end

    class FileNotFound < MachineryError; end
    class DirectoryAlreadyExists < MachineryError; end
    class BrokenMetaData < MachineryError; end
    class UnknownSystemdUnitState < MachineryError; end
    class InvalidPager < MachineryError; end
    class InvalidCommandLine < MachineryError; end
  end
end
