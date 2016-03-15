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

class Migrate2To3 < Migration
  desc <<-EOT
    Schema version 3 stores the analyzed data under the directory
    "analyze" and config files diffs in the config_file_diffs
    subdirectory.
    So the existing directory config-file-diffs needs to be moved.

    It also adds a "package_manager" attribute to the repository.
  EOT

  def migrate
    old_path = File.join(@path, "config-file-diffs")
    new_path = File.join(@path, "analyze", "config_file_diffs")
    if File.directory?(old_path)
      FileUtils.mkdir_p(File.join(@path, "analyze"))
      FileUtils.mv(old_path, new_path)
    end

    if @hash.key?("repositories")
      @hash["repositories"].each do |repository|
        repository["package_manager"] = "zypp"
      end
    end
  end
end
