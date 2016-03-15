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

class Migrate3To4 < Migration
  desc <<-EOT
    Schema version 4 adds a "type" attribute to changed_managed_files and config_files
    in order to support other file types like links.
  EOT

  def migrate
    ["changed_managed_files", "config_files"].each do |scope|
      next unless @hash.key?(scope)

      @hash[scope]["files"].each do |file|
        next if file["changes"] == ["deleted"]

        path = File.join(@path, scope, file["name"])
        file["type"] = if File.directory?(path) || path.end_with?("/")
          "dir"
        else
          "file"
        end
      end
    end

    Dir.glob(File.join(@path, "/changed_managed_files/**/*")).reverse.each do |path|
      if File.directory?(path) && Dir.glob(File.join(path, "*")).empty?
        FileUtils.rm_r(path)
      end
    end

    Dir.glob(File.join(@path, "/config_files/**/*")).reverse.each do |path|
      if File.directory?(path) && Dir.glob(File.join(path, "*")).empty?
        FileUtils.rm_r(path)
      end
    end
  end
end
