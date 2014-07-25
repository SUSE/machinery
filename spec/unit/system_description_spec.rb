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

describe SystemDescription do
  before(:all) do
    @name = "name"
    @description = '{
      "repositories": [
        {
          "alias": "YaST:Head",
          "name": "YaST:Head",
          "url": "http://download.opensuse.org",
          "type": "rpm-md",
          "priority": 99,
          "keep_packages": false,
          "enabled": true,
          "autorefresh": true
        }
      ],
      "packages": [
        {
          "name": "kernel-desktop",
          "version": "3.7.10-1.16.1"
        }
      ],
      "meta": {
        "packages": {
          "modified": "2014-02-07T14:04:45Z",
          "hostname": "192.168.122.216"
        }
      }
    }'
    @duplicate_description = '{
      "packages": [
        {
          "name": "kernel-desktop",
          "version": "3.7.10-1.16.1"
        },
        {
          "name": "kernel-desktop",
          "version": "3.7.10-1.16.1"
        }
      ]
    }'
    @empty_description = '{
    }'
    @mix_struct_hash_descr = '{
      "software": {
        "packages": {
          "foo": "bar"
        }
      }
    }'
    class OsInspector
      alias orig_inspect inspect
      def inspect(system, description, options = {})
        json = <<-EOF
        {
          "os": {
          "name": "SUSE Linux Enterprise Server 12"
          }
        }
        EOF
        system_description = SystemDescription.from_json("localhost", json)
        description.os = system_description.os
      end
    end
  end

  after(:all) do
    class OsInspector
      alias inspect orig_inspect
      remove_method(:orig_inspect)
    end
  end

  it "returns empty JSON structure on .new" do
    data = SystemDescription.new("foo")
    expect(data.to_json.delete(' ')).to eq(@empty_description.delete(' '))
  end

  it "provides nested accessors for data attributes" do
    data = SystemDescription.from_json(@name, @description)
    expect(data.repositories.first.alias).to eq("YaST:Head")
  end

  it "supports serialization from and to json" do
    data = SystemDescription.from_json(@name, @description)
    expect(data.to_json.delete(' ')).to eq(@description.delete(' '))
  end

  it "allows mixture of object and hash in json serialization" do
    data = SystemDescription.new("foo")
    data.software = Machinery::Object.new
    data.software.packages = Hash.new
    data.software.packages["foo"] = "bar"
    expect(data.to_json.delete(' ')).to eq(@mix_struct_hash_descr.delete(' '))
  end

  it "raises InvalidSystemDescription if json input does not start with a hash" do
    class SystemDescriptionFooConfig < Machinery::Object; end
    expect { SystemDescription.from_json(@name,
      '[ "system-description-foo", "xxx" ]'
    )}.to raise_error(Machinery::InvalidSystemDescription)
  end

  it "raises ValidationError if json validator find duplicate packages" do
    SystemDescription.add_validator "/packages" do |json|
      if json != json.uniq
        raise Machinery::ValidationError,
          "The description contains duplicate packages."
      end
    end
    expect { SystemDescription.from_json(@name,
      @duplicate_description
    )}.to raise_error(Machinery::ValidationError)
  end

  describe "#scopes" do
    it "returns a sorted list of scopes which are available in the system description" do
      description = SystemDescription.from_json(@name, @description)
      expect(description.scopes).to eq(["packages", "repositories"])
    end
  end

  describe "#assert_scopes" do
    it "checks the system description for completeness" do
      full_description = SystemDescription.from_json(@name, @description)
      [
        ["repositories"],
        ["packages"],
        ["repositories", "packages"]
      ].each do |missing|
        expect {
          description = full_description.dup
          missing.each do |element|
            description.send("#{element}=", nil)
          end
          description.assert_scopes("repositories", "packages")
        }.to raise_error(
           Machinery::SystemDescriptionIncomplete,
           /: #{missing.join(", ")}\./)
      end
    end
  end

  describe "#short_os_version" do
    it "checks for the os scope" do
      json = <<-EOF
        {
        }
      EOF
      description = SystemDescription.from_json("name", json)

      expect {
        description.short_os_version
      }.to raise_error(Machinery::SystemDescriptionIncomplete)
    end

    it "parses openSUSE versions" do
      json = <<-EOF
        {
          "os": {
            "name": "openSUSE 13.1 (Bottle)",
            "version": "13.1 (Bottle)"
          }
        }
      EOF
      description = SystemDescription.from_json("name", json)

      expect(description.short_os_version).to eq("13.1")
    end

    it "parses SLES versions with SP" do
      json = <<-EOF
        {
          "os": {
            "name": "SUSE Linux Enterprise Server 11",
            "version": "11 SP3"
          }
        }
      EOF
      description = SystemDescription.from_json("name", json)

      expect(description.short_os_version).to eq("sles11sp3")
    end

    it "parses SLES versions without SP" do
      json = <<-EOF
        {
          "os": {
            "name": "SUSE Linux Enterprise Server 12",
            "version": "12"
          }
        }
      EOF
      description = SystemDescription.from_json("name", json)

      expect(description.short_os_version).to eq("sles12")
    end

    it "omits Beta/RC versions" do
      json = <<-EOF
        {
          "os": {
            "name": "SUSE Linux Enterprise Server 12",
            "version": "12 Beta 7"
          }
        }
      EOF
      description = SystemDescription.from_json("name", json)

      expect(description.short_os_version).to eq("sles12")
    end
  end

  describe "#scope_extracted?" do
    let(:description) {
      json = <<-EOF
        {
          "config-files": []
        }
      EOF
      description = SystemDescription.from_json("name", json)
    }

    it "returns true" do
      description.store = double(file_store: "/path/to/foo")
      expect(description.scope_extracted?("config-files")).to be(true)
    end

    it "returns false" do
      description.store = double(file_store: nil)
      expect(description.scope_extracted?("config-files")).to be(false)
    end
  end

  describe "#buildhost" do
    let(:description) {
      json = <<-EOF
        {
          "os": {
          "name": "openSUSE 13.1 (Bottle)"
          }
        }
      EOF
      description = SystemDescription.from_json("name", json)
    }

    it "returns OsSLE12 object" do
      expect(description.buildhost).to be_a(OsSLE12)
    end

    it "raises Machinery::UnsupportedHostForImageError if build host is unsupported" do
      class OsInspector
        def inspect(system, description, options = {})
          json = <<-EOF
          {
            "os": {
            "name": "SUSE Linux Enterprise Server 13"
            }
          }
          EOF
          system_description = SystemDescription.from_json("localhost", json)
          description.os = system_description.os
        end
      end
      expect { description.buildhost }.to raise_error(Machinery::UnsupportedHostForImageError, /Unsupported build host distribution/)
    end
  end
end
