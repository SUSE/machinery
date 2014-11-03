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
  attr_reader :can_build, :name

  def self.descendants
    ObjectSpace.each_object(::Class).select { |klass| klass < self }
  end

  def self.for(os_name)
    descendants.each do |os_class|
      os_object = os_class.new
      if os_name == os_object.name
        return os_object
      end
    end
    raise Machinery::Errors::UnknownOs.new("Unknown OS: '#{os_name}'")
  end

  def can_build?(os)
    if os.is_a?(Class)
      return @can_build.include?(os)
    else
      return @can_build.include?(os.class)
    end
  end

  def module_required_by_package(package)
    if @module_required_by_package
      return @module_required_by_package[package]
    end
  end

  def can_run_machinery?
    @can_run_machinery
  end
end

class OsSles11 < Os
  def initialize
    @can_build = []
    @name = "SUSE Linux Enterprise Server 11"
  end
end

class OsSles12 < Os
  def initialize
    @can_build = [OsSles12]
    @name = "SUSE Linux Enterprise Server 12"
    @module_required_by_package = {
      "python-glanceclient" => "Public Cloud Module"
    }
    @can_run_machinery = true
  end
end

class OsOpenSuse13_1 < Os
  def initialize
    @can_build = [OsSles11, OsOpenSuse13_1]
    @name = "openSUSE 13.1 (Bottle)"
    @can_run_machinery = true
  end
end

class OsOpenSuse13_2 < Os
  def initialize
    @can_build = [OsSles11, OsOpenSuse13_1, OsOpenSuse13_2]
    @name = "openSUSE 13.2 (Harlequin)"
    @can_run_machinery = true
  end
end
