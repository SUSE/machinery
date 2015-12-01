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

class Migrate5To6 < Migration
  desc <<-EOT
    Schema version 6 adds support for Ubuntu 14.04 systems.
    There are now three types of repositories: zypper, yum and apt
  EOT

  def migrate
    if @hash.key?("packages")
      @hash["packages"] = {
        "_attributes" => {
          "package_system" => "rpm"
        },
        "_elements" => @hash["packages"]
      }
    end
    if @hash.key?("repositories")
      @hash["repositories"] = {
        "_attributes" => {
          "repository_system" => @hash["repositories"].first["package_manager"]
        },
        "_elements" => @hash["repositories"].map do |repository|
          repository.delete_if { |key, _| key == "package_manager" }
        end
      }
    end
    ["changed_managed_files", "config_files", "unmanaged_files"].each do |scope|
      next unless @hash.key?(scope)

      @hash[scope] = {
        "_attributes" => {
          "extracted" => @hash[scope]["extracted"]
        },
        "_elements" => @hash[scope]["files"]
      }
    end

    ["changed_managed_files", "config_files"].each do |scope|
      next unless @hash.key?(scope)

      @hash[scope]["_elements"] = @hash[scope]["_elements"].map do |file|
        file["changes"] = {
          "_attributes" => {},
          "_elements" => file["changes"]
        }
        file
      end
    end

    if @hash.key?("services")
      @hash["services"] = {
        "_attributes" => {
          "init_system" => @hash["services"]["init_system"]
        },
        "_elements" => @hash["services"]["services"]
      }
    end

    ["users", "groups", "patterns"].each do |scope|
      next unless @hash.key?(scope)

      @hash[scope] = {
        "_attributes" => {},
        "_elements" => @hash[scope]
      }
    end

    @hash
  end
end
