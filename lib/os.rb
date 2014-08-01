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

class Os
  attr_reader :can_build

  def can_build?(os)
    if os.is_a?(Class)
      return @can_build.include?(os)
    else
      return @can_build.include?(os.class)
    end
  end
end

class OsSles11 < Os
  def initialize
    @can_build = [OsSles11]
    @name = "SUSE Linux Enterprise Server 11"
  end
end

class OsSles12 < Os
  def initialize
    @can_build = [OsSles12]
    @name = "SUSE Linux Enterprise Server 12"
  end
end

class OsOpenSuse13_1 < Os
  def initialize
    @can_build = [OsSles11, OsSles12]
    @name = "openSUSE 13.1 (Bottle)"
  end
end
