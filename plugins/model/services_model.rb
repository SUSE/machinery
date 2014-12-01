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

class ServiceList < Machinery::Array
  has_elements class: Service
end

class ServicesScope < Machinery::Object
  include Machinery::ScopeMixin
  has_property :services, class: ServiceList

  def compare_with(other)
    if self.init_system != other.init_system
      [self, other, nil]
    else
      [
        self.services - other.services,
        other.services - self.services,
        self.services & other.services
      ].map do |services|
        if !services.empty?
          self.class.new(:init_system => self.init_system, :services => services)
        else
          nil
        end
      end
    end
  end
end

