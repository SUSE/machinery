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

require_relative "file_scope"

class UnmanagedFile < Machinery::Object
end

class UnmanagedFileList < Machinery::Array
  has_elements class: UnmanagedFile

  def compare_with(other)
    only_self = elements.reject do |element|
      other.elements.find { |other_element| files_match(element, other_element) }
    end
    only_other = other.elements.reject do |element|
      elements.find { |other_element| files_match(element, other_element) }
    end
    both = elements.select do |element|
      other.elements.find { |other_element| files_match(element, other_element) }
    end

    [
      self.class.new(only_self),
      self.class.new(only_other),
      self.class.new(both)
    ].map { |e| !e.empty? ? e : nil }
  end

  private

  def files_match(a, b)
    common_attributes = a.attributes.keys & b.attributes.keys
    common_attributes.all? do |attribute|
      a[attribute] == b[attribute]
    end
  end
end

class UnmanagedFilesScope < FileScope
  include Machinery::ScopeMixin
  has_property :files, class: UnmanagedFileList

  def compare_with(other)
    if extracted != other.extracted
      Machinery::Ui.warn("Warning: Comparing extracted with unextracted" \
        " unmanaged files. Only common attributes are considered.")
    end

    super
  end
end
