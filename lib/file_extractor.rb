# Copyright (c) 2013-2015 SUSE LLC
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

# FileExtractor provides a uniform method of extracting files and trees from a system
class FileExtractor
  attr_accessor :system, :scope_file_store

  def initialize(system, scope_file_store)
    @system = system
    @scope_file_store = scope_file_store
  end

  def extract_files(file_list, excluded_paths)
    archive_path = File.join(@scope_file_store.path, "files.tgz")
    @system.create_archive(file_list.join("\0"), archive_path, excluded_paths)
  end

  def extract_trees(trees, excluded_paths)
    trees.each do |tree|
      tree_name = File.basename(tree)
      parent_dir = File.dirname(tree)
      sub_dir = File.join("trees", parent_dir)

      @scope_file_store.create_sub_directory(sub_dir)
      archive_path = File.join(@scope_file_store.path, sub_dir, "#{tree_name}.tgz")
      @system.create_archive(tree, archive_path, excluded_paths)
    end
  end
end
