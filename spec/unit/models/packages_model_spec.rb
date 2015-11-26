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

require_relative "../spec_helper"

describe "packages model" do
  let(:scope) {
    json = create_test_description_json(scopes: ["packages"])
    PackagesScope.from_json(JSON.parse(json)["packages"])
  }

  it_behaves_like "Scope"

  specify { expect(scope.packages.first).to be_a(Package) }

  it "has correct scope name" do
    expect(PackagesScope.new.scope_name).to eq("packages")
  end

  describe "#compare_with" do
    let(:description1) {
      create_test_description(json: <<-EOF, name: "description1")
        {
          "packages": {
            "package_system": "rpm",
            "packages": [
              {
                "name": "bash",
                "version": "4.2",
                "release": "1.0",
                "arch": "x86_64",
                "vendor": "openSUSE",
                "checksum": "7dfdd742a9b7d60c75bf4844d294716d"
              },
              {
                "name": "kernel-desktop",
                "version": "3.7.10",
                "release": "1.0",
                "arch": "i586",
                "vendor": "openSUSE",
                "checksum": "4a87f6b9ceae5d40a411fe52d0f17050"
              },
              {
                "name": "autofs",
                "version": "5.0.9",
                "release": "3.6",
                "arch": "x86_64",
                "vendor": "openSUSE",
                "checksum": "6d5d012b0e8d33cf93e216dfab6b174e"
              },
              {
                "name": "btrfsprogs",
                "version": "3.16",
                "release": "4.1",
                "arch": "x86_64",
                "vendor": "openSUSE",
                "checksum": "db96018161193aaa42ee8cd1234247f9"
              },
              {
                "name": "cpio",
                "version": "2.11",
                "release": "26.182",
                "arch": "x86_64",
                "vendor": "SUSE LLC <https://www.suse.com/>",
                "checksum": "091d486ab725d7542933b74f9b3204e4"
              },
              {
                "name": "konsole",
                "version": "5.1",
                "release": "1.1",
                "arch": "x86_64",
                "vendor": "SUSE LLC <https://www.suse.com/>",
                "checksum": "091d486ab725d7542933b74f9b3204e4"
              }
            ]
          }
        }
      EOF
    }
    let(:description2) {
      create_test_description(json: <<-EOF, name: "description2")
        {
          "packages": {
            "package_system": "rpm",
            "packages": [
              {
                "name": "bash2",
                "version": "4.2",
                "release": "1.0",
                "arch": "x86_64",
                "vendor": "openSUSE",
                "checksum": "7dfdd742a9b7d60c75bf4844d294716d"
              },
              {
                "name": "kernel-desktop",
                "version": "3.7.11",
                "release": "1.0",
                "arch": "i586",
                "vendor": "openSUSE",
                "checksum": "4a87f6b9ceae5d40a411fe52d0f17050"
              },
              {
                "name": "autofs",
                "version": "5.0.9",
                "release": "3.6",
                "arch": "x86_64",
                "vendor": "Packman",
                "checksum": "6d5d012b0e8d33cf93e216dfab6b174e"
              },
              {
                "name": "btrfsprogs",
                "version": "3.18",
                "release": "4.1",
                "arch": "x86_64",
                "vendor": "Packman",
                "checksum": "db96018161193aaa42ee8cd1234247f9"
              },
              {
                "name": "cpio",
                "version": "2.11",
                "release": "26.184",
                "arch": "x86_64",
                "vendor": "SUSE LLC <https://www.suse.com/>",
                "checksum": "091d486ab725d7542933b74f9b3204e4"
              },
              {
                "name": "konsole",
                "version": "5.1",
                "release": "1.1",
                "arch": "x86_64",
                "vendor": "SUSE LLC <https://www.suse.com/>",
                "checksum": "091d486ab725d7542933b74f9b3204e4"
              }
            ]
          }
        }
      EOF
    }
    let(:comparison) { description1.packages.compare_with(description2.packages) }

    it "detects packages only in description1" do
      expect(comparison[0].packages.map(&:name)).to eq(["bash"])
    end

    it "detects packages only in description1" do
      expect(comparison[1].packages.map(&:name)).to eq(["bash2"])
    end

    it "detects changed packages" do
      expect(comparison[2].length).to eq(4)
      expect(comparison[2].first).to eq(
        [
          Package.new(
            name: "kernel-desktop",
            version: "3.7.10",
            release: "1.0",
            arch: "i586",
            vendor: "openSUSE",
            checksum: "4a87f6b9ceae5d40a411fe52d0f17050"
          ),
          Package.new(
            name: "kernel-desktop",
            version: "3.7.11",
            release: "1.0",
            arch: "i586",
            vendor: "openSUSE",
            checksum: "4a87f6b9ceae5d40a411fe52d0f17050"
          )
        ]
      )
    end

    it "detects packages in both" do
      expect(comparison[3].packages.map(&:name)).to eq(["konsole"])
    end
  end
end
