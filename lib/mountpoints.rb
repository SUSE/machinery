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

# MountPoints represents the currently mounted file systems of the
# inspected system.
#
# all()     returns an array containing the mount points of all mounted
#           file systems
#
# remote()  returns an array containing the mount points of all mounted
#           file systems that are remote file systems (e.g. nfs, cifs)
#
# special() returns an array containing the mount points of all mounted
#            special file systems, e.g. /proc
#
# local()   returns an array containing the mount points of all mounted
#           local file systems with permanent data (e.g. ext3, btrfs, xfs)


class MountPoints
  attr_reader :mounts
  REMOTE_FILE_SYSTEMS = ["autofs", "cifs", "nfs", "nfs4"]
  SPECIAL_FILE_SYSTEMS = ["proc", "sysfs", "devtmpfs", "tmpfs", "fuse.gvfs-fuse-daemon"]
  LOCAL_FILE_SYSTEMS  = ["ext2", "ext3", "ext4", "reiserfs", "btrfs", "vfat", "xfs", "jfs"]
  def initialize(system)
    @mounts = parse_mounts(system.read_file("/proc/mounts"))
  end

  def special
    @mounts.select { |_fs_file, fs_vfstype| special_fs?(fs_vfstype) }.keys
  end

  def remote
    @mounts.select { |_fs_file, fs_vfstype| remote_fs?(fs_vfstype) }.keys
  end

  def local
    @mounts.select { |_fs_file, fs_vfstype| local_fs?(fs_vfstype) }.keys
  end

  def all
    @mounts.keys
  end


  private

  def parse_mounts(proc_mounts)
    # /proc/mounts can contain multiple lines for the same fs_file
    # we store the latest entry only, because that's the relevant one
    mounts = Hash.new
    proc_mounts.each_line do |line|
      _fs_spec, fs_file, fs_vfstype, _fs_mntops, _fs_freq, _fs_passno = line.split(" ")
      mounts[fs_file] = fs_vfstype
    end
    mounts
  end

  def special_fs?(fs)
    SPECIAL_FILE_SYSTEMS.include?(fs)
  end

  def remote_fs?(fs)
    REMOTE_FILE_SYSTEMS.include?(fs)
  end

  def local_fs?(fs)
    LOCAL_FILE_SYSTEMS.include?(fs)
  end
end
