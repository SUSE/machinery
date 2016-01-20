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

class FileDiff
  def self.diff(description1, description2, scope, path)
    return nil if !description1.scope_extracted?(scope) || !description2.scope_extracted?(scope)

    file1 = description1[scope].find { |f| f.name == path }
    file2 = description2[scope].find { |f| f.name == path }
    return nil if !file1 || !file2

    if file1.binary? || file2.binary?
      raise Machinery::Errors::BinaryDiffError, "Can't diff binary files"
    end

    Diffy::Diff.new(file1.content, file2.content, include_plus_and_minus_in_html: true)
  end
end
