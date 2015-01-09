# encoding: utf-8
#
# Copyright (c) 2013-2015 SUSE LLC
#
## This program is free software; you can redistribute it and/or
## modify it under the terms of version 3 of the GNU General Public License as
## published by the Free Software Foundation.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, contact SUSE LLC.
##
## To contact SUSE about this file by physical or electronic mail,
## you may find current contact information at www.suse.com

require "abstract_method"
require "json"
require_relative "../lib/constants"
require_relative "../lib/object"
require_relative "../lib/exceptions"
require_relative "../lib/system_description"
require_relative "../lib/system_description_store"
require_relative "../lib/migration"

# descriptions can be provided to prevent it from using every directory in the
# description path
def upgrade_descriptions(path, descriptions = [])
  store = SystemDescriptionStore.new(path)
  if descriptions.empty?
    descriptions = Dir.entries(path).reject { |e| e =~ /^\.{1,2}$/ }
  end

  descriptions.each do |description|
    Migration.migrate_description(store, description)
  end
end

def update_json_format_version(dir_with_json_file_path)
  json_files = Dir.glob(File.join(dir_with_json_file_path, "*.json"))
  json_files.each do |json_file|
    json_hash = JSON.parse(File.read(json_file))
    json_hash["meta"]["format_version"] = SystemDescription::CURRENT_FORMAT_VERSION
    File.write(json_file, JSON.pretty_generate(json_hash))
  end
end
