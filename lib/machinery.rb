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

require 'ostruct'
require 'json'
require 'json-pointer'
require "abstract_method"
require "cheetah"
require "tmpdir"
require 'tempfile'
require "time"
require "logger"
require "erb"
require "yaml"
require "uri"
require "gli"

require_relative 'host_capabilities'
require_relative 'machinery_logger'
require_relative 'zypper'
require_relative 'rpm'
require_relative 'array'
require_relative 'object'
require_relative 'system_description'
require_relative 'version'
require_relative 'tarball'
require_relative 'exceptions'
require_relative 'constants'
require_relative 'inspector'
require_relative 'system'
require_relative 'local_system'
require_relative 'remote_system'
require_relative 'current_user'
require_relative 'inspect_task'
require_relative 'inspector'
require_relative 'build_task'
require_relative 'kiwi_config'
require_relative 'renderer'
require_relative 'show_task'
require_relative 'compare_task'
require_relative 'remove_task'
require_relative 'list_task'
require_relative 'system_description_store'
require_relative 'logged_cheetah'
require_relative 'renderer_helper'
require_relative 'changed_rpm_files_helper'
require_relative 'kiwi_export_task'
require_relative 'helper'
require_relative 'deploy_task'
require_relative 'analyze_config_file_diffs_task'
require_relative 'copy_task'
require_relative 'scope'
require_relative 'output'

Dir[File.join(Machinery::ROOT, "plugins", "**", "*.rb")].each { |f| require(f) }

# this file needs be loaded last, because it immediately collects the loaded inspectors
require_relative 'cli'
