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

class Machinery::Migrate9To10 < Machinery::Migration
  desc <<-EOT
    Add meta data information regarding subdirectories to unmanaged files. The subdirectory
    count is not available for migrated descriptions so the sum of both is called file_objects.
    Add an attribute to the patterns scope which identifies pattern management on the inspected
    system (tasksel on Debian, zypper on SUSE).
  EOT

  def migrate
    if @hash.key?("unmanaged_files")
      @hash["unmanaged_files"]["_elements"].each do |element|
        if element["type"] == "dir" && element["files"]
          element["file_objects"] = element.delete("files")
        end
      end
    end

    if @hash.key?("patterns")
      if @hash.key?("packages")
        patterns_system = if @hash["packages"]["_attributes"]["package_system"] == "dpkg"
          "tasksel"
        else
          "zypper"
        end
      else
        patterns_system = "zypper"
        Machinery::Ui.warn("No packages scope found. Patterns system defaults to zypper.")
      end

      @hash["patterns"] = {
        "_attributes" => {
          "patterns_system" => patterns_system
        },
        "_elements" => @hash["patterns"]["_elements"]
      }
    end
  end
end
