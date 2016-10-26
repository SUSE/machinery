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
  class Service < Machinery::Object
    def enabled?
      # systemd vs sysvinit
      state == "enabled" || state == "on"
    end

    def disabled?
      # systemd vs sysvinit
      state == "disabled" || state == "off"
    end
  end

  class ServicesScope < Machinery::Array
    include Machinery::Scope

    has_attributes :init_system
    has_elements class: Service

    def compare_with(other)
      if init_system != other.init_system
        [self, other, nil, nil]
      else
        only_self = self - other
        only_other = other - self
        common = self & other
        changed = Machinery::Scope.extract_changed_elements(only_self, only_other, :name)
        changed = nil if changed.empty?

        [
          service_list_to_scope(only_self),
          service_list_to_scope(only_other),
          changed,
          service_list_to_scope(common)
        ].map { |e| e && !e.empty? ? e : nil }
      end
    end

    private

    def service_list_to_scope(services)
      self.class.new(services, init_system: init_system) unless services.elements.empty?
    end
  end
end
