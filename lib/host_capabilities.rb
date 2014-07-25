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

class OsBuild
  # map names from OsInspector to symbols
  @@systems_map = {
    :OsSLE12 => "SUSE Linux Enterprise Server 12",
    :OsSLE11 => "SUSE Linux Enterprise Server 11",
    :OsOpenSUSE131 => "openSUSE 13.1 (Bottle)"
  }

  # basic systems we allow to start a build on
  @@supported_buildhosts = [:OsSLE12, :OsOpenSUSE131]

  def initialize(can_build, for_os)
    if !for_os.is_a?(Symbol)
      @for_os = self.class.os_to_sym(for_os)
    else
      @for_os = for_os
    end
    @can_build = can_build
  end

  def can_build?
    @can_build.include?(@for_os)
  end

  def can_build
    result = Array.new
    @can_build.each do |item|
      result.push(self.class.sym_to_os(item))
    end
    result.join(',')
  end

  def os_name
    self.class.sym_to_os(self.class.name.to_sym)
  end

  def self.supported_buildhost?(host)
    @@supported_buildhosts.include?(self.os_to_sym(host))
  end

  def self.supported_buildhost
    result = Array.new
    @@supported_buildhosts.each do |name|
      result.push(self.sym_to_os(name))
    end
    result.join(',')
  end

  def self.instance_for(buildhost, buildimage)
    klass = buildhost
    if !buildhost.is_a?(Symbol)
      klass = self.os_to_sym(buildhost)
    end
    Object.const_get(klass).new(buildimage)
  end

  private

  def self.os_to_sym(name)
    @@systems_map.each do |key, value|
      if value == name
        return key
      end
    end
    nil
  end

  def self.sym_to_os(name)
    @@systems_map[name]
  end
end

# build capabilities of SLES 12 buildhost
class OsSLE12 < OsBuild
  def initialize(for_os)
    can_build = [:OsSLE12]
    super(can_build, for_os)
  end
end

# build capabilities of openSUSE 13.1 buildhost
class OsOpenSUSE131 < OsBuild
  def initialize(for_os)
    can_build = [:OsSLE12, :OsSLE11]
    super(can_build, for_os)
  end
end

