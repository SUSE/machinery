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
  class ValidationError < StandardError; end
  class UnknownInspectorError < StandardError; end
  class SshConnectionFailed < StandardError; end
  class SystemDescriptionNotFoundError < StandardError; end
  class SystemDescriptionAlreadyExistsError < StandardError; end
  class SystemRequirementError < StandardError; end
  class RsyncFailed < StandardError; end
  class SystemDescriptionIncomplete < StandardError; end
  class UnsupportedOperatingSystem < StandardError; end
  class UnknownRendererError < StandardError; end
  class FileNotFoundError < StandardError; end
  class FailedScopeError < StandardError; end
  class DirectoryAlreadyExistsError < StandardError; end
  class MissingRequirementsError < StandardError; end
  class BuildError < StandardError; end
  class BrokenMetaData < StandardError; end
  class UnknownSystemdUnitState < StandardError; end
  class SystemDescriptionNameInvalid < StandardError; end
  class InvalidOsUpgradePath < StandardError; end
  class InvalidSystemDescription < StandardError; end
  class InvalidPagerError < StandardError; end
  class InvalidCommandLine < StandardError; end
  class UnsupportedHostForImageError < StandardError; end
end
