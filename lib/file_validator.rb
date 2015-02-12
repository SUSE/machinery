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

class FileValidator
  class <<self
    def validate(file_store, expected)
      missing_files = missing_files(expected)
      additional_files = additional_files(expected, file_store)

      format_file_errors(missing_files, additional_files)
    end

    private

    def missing_files(file_list)
      file_list.select { |file| !File.exists?(file) }
    end

    def additional_files(file_list, file_store)
      file_store.list_content - file_list
    end

    def format_file_errors(missing_files, additional_files)
      errors = []
      errors += missing_files.map do |file|
        "  * File '" + file + "' doesn't exist"
      end
      errors += additional_files.map do |file|
        "  * File '" + file + "' doesn't have meta data"
      end
    end
  end
end
