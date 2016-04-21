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

class Migrate8To9 < Migration
  desc <<-EOT
    Format version 9 fixes the filter paths for migrated descriptions.
  EOT

  def migrate
    meta = @hash["meta"]
    if meta.key?("filters") && meta["filters"].key?("inspect")
      meta["filters"]["inspect"] = meta["filters"]["inspect"].map do |element|
        element.gsub(/^(\/[a-z_]+\/)files\//, "\\1")
      end

      meta["filters"]["inspect"] = meta["filters"]["inspect"].map do |element|
        element.gsub(/^\/services\/services\//, "/services/")
      end
    end
  end
end
