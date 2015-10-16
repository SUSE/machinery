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

class FileScope < Machinery::Object
  def compare_with(other)
    validate_attributes(other)

    only_self = self.class.new
    only_other = self.class.new
    shared = self.class.new

    compare_extracted(other, only_self, only_other, shared)
    changed = compare_files(other, only_self, only_other, shared)

    only_self = nil if only_self.empty?
    only_other = nil if only_other.empty?
    shared = nil if shared.empty?
    [only_self, only_other, changed, shared]
  end

  private

  def validate_attributes(other)
    expected_attributes = ["extracted", "files"]
    actual_attributes = (attributes.keys + other.attributes.keys).uniq.sort

    if actual_attributes != expected_attributes
      unsupported = actual_attributes - expected_attributes
      raise Machinery::Errors::MachineryError.new(
        "The following attributes are not covered by FileScope#compare_with: " +
          unsupported.join(", ")
      )
    end
  end

  def compare_extracted(other, only_self, only_other, shared)
    if extracted == other.extracted
      shared.extracted = extracted
    else
      only_self.extracted = extracted
      only_other.extracted = other.extracted
    end
  end

  def compare_files(other, only_self, only_other, shared)
    own_files, other_files, changed, shared_files = files.compare_with(other.files)

    only_self.files = own_files if own_files
    only_other.files = other_files if other_files
    shared.files = shared_files if shared_files

    changed
  end
end
