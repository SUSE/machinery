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

require_relative "spec_helper"

describe ServicesScope do
  describe "#compare_with" do
    let(:service_a) { Service::new(:name => "a", :state => "enabled") }
    let(:service_b) { Service::new(:name => "b", :state => "enabled") }
    let(:service_c) { Service::new(:name => "c", :state => "enabled") }
    let(:service_d) { Service::new(:name => "d", :state => "enabled") }
    let(:service_e) { Service::new(:name => "e", :state => "enabled") }
    let(:service_f) { Service::new(:name => "f", :state => "enabled") }

    context "when init systems are the same" do
      it "returns correct result when service lists are equal" do
        data_a = ServicesScope.new(
          :init_system => "systemd",
          :services    => [service_a, service_b, service_c]
        )
        data_b = ServicesScope.new(
          :init_system => "systemd",
          :services    => [service_a, service_b, service_c]
        )

        comparison = data_a.compare_with(data_b)

        expect(comparison).to eq([nil, nil, data_a])
      end

      it "returns correct result when service lists aren't equal and don't have common elements" do
        data_a = ServicesScope.new(
          :init_system => "systemd",
          :services    => [service_a, service_b, service_c]
        )
        data_b = ServicesScope.new(
          :init_system => "systemd",
          :services    => [service_d, service_e, service_f]
        )

        comparison = data_a.compare_with(data_b)

        expect(comparison).to eq([data_a, data_b, nil])
      end

      it "returns correct result when service lists aren't equal but have common elements" do
        data_a = ServicesScope.new(
          :init_system => "systemd",
          :services    => [service_a, service_b, service_c, service_d]
        )
        data_b = ServicesScope.new(
          :init_system => "systemd",
          :services    => [service_a, service_b, service_e, service_f]
        )

        comparison = data_a.compare_with(data_b)

        expect(comparison).to eq([
          ServicesScope.new(
            :init_system => "systemd",
            :services    => [service_c, service_d]
          ),
          ServicesScope.new(
            :init_system => "systemd",
            :services    => [service_e, service_f]
          ),
          ServicesScope.new(
            :init_system => "systemd",
            :services    => [service_a, service_b]
          )
        ])
      end
    end

    context "when init systems are different" do
      it "treats the data as completely different" do
        data_a = ServicesScope.new(
          :init_system => "sysvinit",
          :services    => [service_a, service_b, service_c]
        )
        data_b = ServicesScope.new(
          :init_system => "systemd",
          :services    => [service_a, service_b, service_c]
        )

        comparison = data_a.compare_with(data_b)

        expect(comparison).to eq([data_a, data_b, nil])
      end
    end
  end
end
