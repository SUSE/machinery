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

require_relative "../spec_helper"

describe "services model" do
  let(:scope) {
    json = create_test_description_json(scopes: ["services"])
    Machinery::ServicesScope.from_json(JSON.parse(json)["services"])
  }

  it_behaves_like "Scope"

  specify { expect(scope).to be_a(Machinery::ServicesScope) }
  specify { expect(scope.first).to be_a(Machinery::Service) }

  describe Machinery::ServicesScope do
    describe "#length" do
      it "returns the number of services" do
        expect(scope.length).to eq(14)
      end
    end

    describe "#compare_with" do
      let(:service_a) { Machinery::Service.new(name: "a", state: "enabled") }
      let(:service_b) { Machinery::Service.new(name: "b", state: "enabled") }
      let(:service_c) { Machinery::Service.new(name: "c", state: "enabled") }
      let(:service_d) { Machinery::Service.new(name: "d", state: "enabled") }
      let(:service_e) { Machinery::Service.new(name: "e", state: "enabled") }
      let(:service_f) { Machinery::Service.new(name: "f", state: "enabled") }

      context "when init systems are the same" do
        it "returns correct result when service lists are equal" do
          data_a = Machinery::ServicesScope.new(
            [service_a, service_b, service_c],
            init_system: "systemd"
          )
          data_b = Machinery::ServicesScope.new(
            [service_a, service_b, service_c],
            init_system: "systemd"
          )

          comparison = data_a.compare_with(data_b)
          expect(comparison).to eq([nil, nil, nil, data_a])
        end

        it "returns correct result when lists aren't equal and don't have common elements" do
          data_a = Machinery::ServicesScope.new(
            [service_a, service_b, service_c],
            init_system: "systemd"
          )
          data_b = Machinery::ServicesScope.new(
            [service_d, service_e, service_f],
            init_system: "systemd"
          )

          comparison = data_a.compare_with(data_b)

          expect(comparison).to eq([data_a, data_b, nil, nil])
        end

        it "returns correct result when service lists aren't equal but have common elements" do
          data_a = Machinery::ServicesScope.new(
            [service_a, service_b, service_c, service_d],
            init_system: "systemd"
          )
          data_b = Machinery::ServicesScope.new(
            [service_a, service_b, service_e, service_f],
            init_system: "systemd"
          )

          comparison = data_a.compare_with(data_b)

          expect(comparison).to eq(
            [
              Machinery::ServicesScope.new(
                [service_c, service_d],
                init_system: "systemd"
              ),
              Machinery::ServicesScope.new(
                [service_e, service_f],
                init_system: "systemd"
              ),
              nil,
              Machinery::ServicesScope.new(
                [service_a, service_b],
                init_system: "systemd"
              )
            ]
          )
        end
      end

      context "when init systems are different" do
        it "treats the data as completely different" do
          data_a = Machinery::ServicesScope.new(
            [service_a, service_b, service_c],
            init_system: "sysvinit"
          )
          data_b = Machinery::ServicesScope.new(
            [service_a, service_b, service_c],
            init_system: "systemd"
          )

          comparison = data_a.compare_with(data_b)

          expect(comparison).to eq([data_a, data_b, nil, nil])
        end
      end
    end
  end
end
