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

class Machinery::Migrate7To8 < Machinery::Migration
  desc <<-EOT
    Format version 8 renames the scope config-files to changed-config-files.

    Following this change the config_file_diff dir is also renamed to
    changed_config_files_diffs.
  EOT

  def migrate
    if File.directory?(File.join(@path, "config_files"))
      FileUtils.mv(File.join(@path, "config_files"), File.join(@path, "changed_config_files"))
    end

    if File.directory?(File.join(@path, "analyze", "config_file_diffs"))
      FileUtils.mv(
        File.join(@path, "analyze", "config_file_diffs"),
        File.join(@path, "analyze", "changed_config_files_diffs")
      )
    end

    if @hash.key?("config_files")
      @hash["changed_config_files"] = @hash.delete("config_files")
    end

    meta = @hash["meta"]
    if meta.key?("config_files")
      meta["changed_config_files"] = meta.delete("config_files")
    end
  end
end
