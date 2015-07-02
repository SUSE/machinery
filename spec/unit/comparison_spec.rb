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

require_relative "spec_helper"

describe Comparison do
  let(:description1) { create_test_description(name: "description1", scopes: ["packages"]) }
  let(:description2) { create_test_description(name: "description2", scopes: ["packages2"]) }
  let(:empty_description) { create_test_description(name: "empty") }
  subject { Comparison }

  describe ".compare_scope" do
    it "returns a Comparison" do
      expect(subject.compare_scope(description1, description2, "packages")).
        to be_a(Comparison)
    end

    it "returns nil for the mission scope when a description does not have the scope" do
      expect(subject.compare_scope(empty_description, description1, "packages").only_in1).to be(nil)
      expect(subject.compare_scope(description1, empty_description, "packages").only_in2).to be(nil)
    end

    context "result" do
      let(:result) { subject.compare_scope(description1, description2, "packages") }
      let(:expected_only_in1) {
        PackagesScope.new(
          [
            Package.new(
              name: "openSUSE-release-dvd",
              version: "13.1",
              release: "1.10",
              arch: "x86_64",
              vendor: "SUSE LINUX Products GmbH, Nuernberg, Germany",
              checksum: "2a3d5b29179daa1e65e391d0a0c1442d"
            )
          ]
        )
      }
      let(:expected_only_in2) {
        PackagesScope.new(
          [
            Package.new(
              name: "kernel-desktop",
              version: "3.7.10",
              release: "1.0",
              arch: "i586",
              vendor: "openSUSE",
              checksum: "4a87f6b9ceae5d40a411fe52d0f17050"
            )
          ]
        )
      }
      let(:expected_common) {
        PackagesScope.new(
          [
            Package.new(
              name: "autofs",
              version: "5.0.9",
              release: "3.6",
              arch: "x86_64",
              vendor: "Packman",
              checksum: "6d5d012b0e8d33cf93e216dfab6b174e"
            )
          ]
        )
      }

      it "returns the names of the compared descriptions" do
        expect(result.name1).to eq("description1")
        expect(result.name2).to eq("description2")
      end

      it "returns partial scope that's only in description1" do
        expect(result.only_in1).to eq(expected_only_in1)
      end

      it "returns partial scope that's only in description2" do
        expect(result.only_in2).to eq(expected_only_in2)
      end

      it "returns changed elements" do
        expected = [
          [
            Package.new(
              name: "bash",
              version: "4.2",
              release: "68.1.5",
              arch: "x86_64",
              vendor: "openSUSE",
              checksum: "533e40ba8a5551204b528c047e45c169"
            ), Package.new(
              name: "bash",
              version: "4.3",
              release: "68.1.5",
              arch: "x86_64",
              vendor: "openSUSE",
              checksum: "533e40ba8a5551204b528c047e45c169"
            )
          ]
        ]
        expect(result.changed).to eq(expected)
      end

      it "returns common elements" do
        expect(result.common).to eq(expected_common)
      end

      context "#as_description" do
        it "raises an error on unknown description" do
          expect {
            result.as_description(:foo)
          }.to raise_error
        end

        it "returns a description for :one" do
          description = result.as_description(:one)
          expect(description).to be_a(SystemDescription)
          expect(description.name).to eq("description1")
          expect(description.packages).to eq(expected_only_in1)
        end

        it "returns a description for :two" do
          description = result.as_description(:two)
          expect(description).to be_a(SystemDescription)
          expect(description.name).to eq("description2")
          expect(description.packages).to eq(expected_only_in2)
        end

        it "returns a description for :common" do
          description = result.as_description(:common)
          expect(description).to be_a(SystemDescription)
          expect(description.name).to eq("common")
          expect(description.packages).to eq(expected_common)
        end
      end
    end
  end
end
