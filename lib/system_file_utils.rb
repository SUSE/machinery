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

module Machinery
  class SystemFileUtils
    class <<self
      def tarball_path(system_file)
        if system_file.directory?
          File.join(
            system_file.scope.scope_file_store.path,
            "trees",
            File.dirname(system_file.name),
            File.basename(system_file.name) + ".tgz"
          )
        else
          File.join(system_file.scope.scope_file_store.path, "files.tgz")
        end
      end

      def file_path(system_file)
        raise Machinery::Errors::FileUtilsError, "Not a file" if !system_file.file?

        File.join(system_file.scope.scope_file_store.path, system_file.name)
      end

      def write_file(system_file, target)
        raise Machinery::Errors::FileUtilsError, "Not a file" if !system_file.file?

        target_path = File.join(target, system_file.name)
        FileUtils.mkdir_p(File.dirname(target_path))
        FileUtils.cp(file_path(system_file), target_path)
      end

      def write_tarball(system_file, target)
        raise Machinery::Errors::FileUtilsError if !system_file.directory?

        tarball_target = File.join(target, File.dirname(system_file.name))

        FileUtils.mkdir_p(tarball_target)
        FileUtils.cp(tarball_path(system_file), tarball_target)
      end

      def write_files_tarball(file_scope, destination)
        FileUtils.cp(
          File.join(file_scope.scope_file_store.path, "files.tgz"),
          destination
        )
      end

      def write_directory_tarballs(file_scope, destination)
        file_scope.files.select(&:directory?).each do |directory|
          write_tarball(directory, File.join(destination, "trees"))
        end
      end
    end
  end
end
