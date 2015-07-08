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
  class SystemFile < Machinery::Object
    def file?
      type == "file"
    end

    def link?
      type == "link"
    end

    def directory?
      type == "dir"
    end

    def remote_directory?
      type == "remote_dir"
    end

    def deleted?
      if changes && changes.include?("deleted")
        true
      else
        false
      end
    end

    def on_disk?
      assert_scope

      scope.extracted && file? && !deleted?
    end

    def binary?
      assert_scope
      scope.binary?(self)
    end

    def content
      assert_scope
      scope.file_content(self)
    end

    private

    def assert_scope
      return if scope

      raise Machinery::Errors::MachineryError,
        "File store related method unavailable, the SystemFile does not have a Scope associated."
    end
  end
end
