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

module Machinery
  class User < Machinery::Object
    IGNORED_ATTRIBUTES_IN_COMPARISON = [
      "password",
      "encrypted_password",
      "last_changed_date",
      "min_days",
      "max_days",
      "warn_days"
    ].freeze

    # User objects contain some information which is not relevant in the context of comparison (e.g.
    # metadata like "last_changed_date"). In order to ignore these attributes during comparison we
    # have to overwrite some methods.
    def eql?(other)
      relevant_attributes = (attributes.keys & other.attributes.keys) -
        IGNORED_ATTRIBUTES_IN_COMPARISON

      relevant_attributes.all? do |attribute|
        self[attribute] == other[attribute]
      end
    end

    def hash
      @attributes.reject { |k, _v| IGNORED_ATTRIBUTES_IN_COMPARISON.include?(k) }.hash
    end
  end

  class UsersScope < Machinery::Array
    include Machinery::Scope

    has_elements class: User

    def compare_with(other)
      only_self = self - other
      only_other = other - self
      common = self & other
      changed = Machinery::Scope.extract_changed_elements(only_self, only_other, :name)

      [
        only_self,
        only_other,
        changed,
        common
      ].map { |e| (e && !e.empty?) ? e : nil }
    end
  end
end
