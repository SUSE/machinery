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

# The responsibility of the ScopeFileStore class is to represent a sub directory
# of a system description which is used to hold files belonging to a specific
# scope.
class ScopeFileStore
  attr_accessor :base_path, :store_name

  def initialize(base_path, store_name)
    @base_path = base_path
    @store_name = store_name
  end

  def create
    dir = File.join(base_path, store_name)
    create_dir(dir, new_dir_mode)
  end

  def path
    dir = File.join(base_path, store_name)
    Dir.exist?(dir) ? dir : nil
  end

  def remove
    FileUtils.rm_rf(File.join(base_path, store_name))
  end

  def rename(new_store_name)
    FileUtils.mv(path, File.join(base_path, new_store_name))
    @store_name = new_store_name
  end

  def create_sub_directory(sub_dir)
    dir = File.join(base_path, store_name, sub_dir)
    create_dir(dir, new_dir_mode)
  end

  def list_content
    files = Dir.
      glob(File.join(path, "**/*"), File::FNM_DOTMATCH).
      reject { |path| [".", ".."].include?(File.basename(path)) }
    # filter parent directories because they should not be listed separately
    files.reject { |f| files.index { |e| e =~ /^#{f}\/.+/ } }
  end

  def new_dir_mode
    mode = 0700
    if Dir.exist?(base_path)
      mode = File.stat(base_path).mode & 0777
    end
    mode
  end

  def create_dir(dir, mode = 0700)
    unless Dir.exist?(dir)
      FileUtils.mkdir_p(dir, mode: mode)
    end
  end
end
