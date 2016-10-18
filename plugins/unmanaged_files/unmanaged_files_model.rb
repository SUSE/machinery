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

class UnmanagedFile < Machinery::SystemFile
end

class UnmanagedFileList < Machinery::Array
end

class UnmanagedFilesScope < Machinery::FileScope
  include Machinery::Scope
  include Machinery::ScopeFileAccessArchive

  has_attributes :extracted, :has_metadata
  has_elements class: UnmanagedFile

  def compare_with(other)
    if extracted != other.extracted
      Machinery::Ui.warn("Warning: Comparing extracted with unextracted" \
        " unmanaged files. Only common attributes are considered.")
    end

    self_hash = elements.inject({}) { |hash, e| hash[e.name] = e; hash }
    other_hash = other.elements.inject({}) { |hash, e| hash[e.name] = e; hash }

    both = []
    only_self = []
    elements.each do |element|
      if other_hash.key?(element.name) && files_match(element, other_hash[element.name])
        both << element
      else
        only_self << element
      end
    end
    only_other = other.elements.reject do |element|
      self_hash.key?(element.name) && files_match(element, self_hash[element.name])
    end
    changed = Machinery::Scope.extract_changed_elements(only_self, only_other, :name)

    if self.attributes == other.attributes
      common_attributes = self.attributes
    else
      only_self_attributes = self.attributes
      only_other_attributes = other.attributes
    end

    comparison = [
      self.class.new(only_self, only_self_attributes || {}),
      self.class.new(only_other, only_other_attributes || {}),
      changed
    ].map { |e| e.empty? ? nil : e }

    common = if both.empty? && common_attributes && common_attributes.empty?
      nil
    else
      self.class.new(both, common_attributes || {})
    end

    comparison.push(common)
  end

  def contains_metadata?
    @metadata ||= has_metadata || elements.any?(&:user)
  end

  def has_subdir_counts?
    @has_subdirs ||= elements.any?(&:files)
  end

  private

  def files_match(a, b)
    common_attributes = a.attributes.keys & b.attributes.keys
    common_attributes.all? do |attribute|
      a[attribute] == b[attribute]
    end
  end
end
