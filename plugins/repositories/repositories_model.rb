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
  class Repository < Machinery::Object
    def external_medium?
      url.start_with?("cd://", "dvd://", "iso://")
    end
  end

  class ZyppRepository < Repository
    class << self
      def key
        "alias"
      end

      def attributes
        ["name", "url", "type", "enabled", "autorefresh", "gpgcheck", "priority", "gpgkey"]
      end
    end
  end

  class YumRepository < Repository
    class << self
      def key
        "alias"
      end

      def attributes
        ["name", "url", "type", "enabled", "gpgcheck", "priority", "mirrorlist", "gpgkey"]
      end
    end
  end

  class AptRepository < Repository
    class << self
      def key
        "url"
      end

      def attributes
        ["url", "type", "distribution", "components"]
      end
    end
  end

  class RepositoriesScope < Machinery::Array
    include Machinery::Scope

    has_attributes :repository_system
    has_elements class: ZyppRepository, if: { repository_system: "zypp" }
    has_elements class: YumRepository, if: { repository_system: "yum" }
    has_elements class: AptRepository, if: { repository_system: "apt" }

    def compare_with(other)
      if repository_system != other.repository_system
        [self, other, nil, nil]
      else
        only_self = self - other
        only_other = other - self
        changed = Machinery::Scope.extract_changed_elements(only_self, only_other, :alias)
        common = self & other

        [
          only_self,
          only_other,
          changed,
          common
        ].map { |e| (e && !e.empty?) ? e : nil }
      end
    end
  end
end
