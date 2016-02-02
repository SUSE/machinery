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

require_relative "spec_helper"

describe SystemDescription do
  initialize_system_description_factory_store

  subject { SystemDescription.new("foo", SystemDescriptionMemoryStore.new) }

  before(:all) do
    @name = "name"
    @description = create_test_description_json(scopes: ["packages", "repositories"])
    @empty_description = create_test_description_json
    @mix_struct_hash_descr = '{
      "software": {
        "packages": {
          "foo": "bar"
        }
      },
      "meta": {
        "format_version": 6
      }
    }'
  end

  it "returns empty JSON structure on .new" do
    data = SystemDescription.new("foo", SystemDescriptionMemoryStore.new)
    expect(JSON.parse(data.to_json).keys).to eq(["meta"])
  end

  it "provides nested accessors for data attributes" do
    data = create_test_description(name: @name, json: @description)
    expect(data.repositories.first.alias).to eq("nodejs_alias")
  end

  it "supports serialization from and to json" do
    data = create_test_description(name: @name, json: @description)
    expect(data.to_json.delete(' ')).to eq(@description.delete(' '))
  end

  it "allows mixture of object and hash in json serialization" do
    data = SystemDescription.new("foo", SystemDescriptionMemoryStore.new)
    data.software = Machinery::Object.new
    data.software.packages = Hash.new
    data.software.packages["foo"] = "bar"
    expect(data.to_json.delete(' ')).to eq(@mix_struct_hash_descr.delete(' '))
  end

  describe "#initialize" do
    it "creates a proper data model" do
      create_test_description(
        name: "extracted_description",
        store_on_disk: true,
        extracted_scopes: ["unmanaged_files"]
      )

      description = SystemDescription.load("extracted_description",
        system_description_factory_store)
      expect(description.unmanaged_files.scope_file_store.path).to_not be(nil)
    end
  end

  context "meta data methods" do
    let(:date) { "2014-02-07T14:04:45Z" }
    let(:hostname) { "example.com" }
    let(:name) { "example" }
    let(:date_human) { Time.parse(date) }
    let(:system_description) {
      create_test_description(
        scopes: ["packages", "repositories"], modified: date, hostname: hostname,
        name: name, store: SystemDescriptionStore.new
      )
    }

    describe "#host" do
      it "returns the inspected host system" do
        expect(system_description.host).to eq(["example.com"])
      end

      it "returns two different hosts" do
        system_description.packages.meta.hostname = "foo"
        expect(system_description.host).to match_array(["foo", "example.com"])
      end
    end

    describe "#latest_update" do
      it "returns the latest update of the system description" do
        system_description.packages.meta.modified = "2014-02-06T14:04:45Z"
        expect(system_description.latest_update).to eq(date_human)
      end
    end
  end

  describe ".from_hash" do
    it "raises SystemDescriptionError if json input does not start with a hash" do
      class SystemDescriptionFooConfig < Machinery::Object; end
      expect {
        SystemDescription.from_hash(
          @name,
          SystemDescriptionMemoryStore.new,
          JSON.parse('[ "system-description-foo", "xxx" ]')
        )
      }.to raise_error(Machinery::Errors::SystemDescriptionError)
    end
  end

  describe "#compatible?" do
    it "returns true if the format_version is good" do
      subject.format_version = SystemDescription::CURRENT_FORMAT_VERSION
      expect(subject.compatible?).to be(true)
    end

    it "returns false if there is no format version defined" do
      subject.format_version = nil
      expect(subject.compatible?).to be(false)
    end

    it "returns false if the format_version does not match the current format version" do
      subject.format_version = SystemDescription::CURRENT_FORMAT_VERSION - 1
      expect(subject.compatible?).to be(false)

      subject.format_version = SystemDescription::CURRENT_FORMAT_VERSION + 1
      expect(subject.compatible?).to be(false)
    end
  end

  describe "#validate_format_compatibility" do
    it "does not raise an exception if the description format is compatible" do
      subject.format_version = SystemDescription::CURRENT_FORMAT_VERSION
      expect {
        subject.validate_format_compatibility
      }.to_not raise_error
    end

    it "raises an exception if the description format is incompatible" do
      subject.format_version = SystemDescription::CURRENT_FORMAT_VERSION - 1
      expect {
        subject.validate_format_compatibility
      }.to raise_error
    end
  end

  describe "#to_hash" do
    it "saves version metadata for descriptions with format version" do
      description = create_test_description(name: "name", json: <<-EOT)
        {
          "meta": {
            "format_version": #{SystemDescription::CURRENT_FORMAT_VERSION}
          }
        }
      EOT

      hash = description.to_hash

      expect(hash["meta"]["format_version"]).to eq(SystemDescription::CURRENT_FORMAT_VERSION)
    end

    it "doesn't save version metadata for descriptions without format version" do
      description = create_test_description(name: "name", json: "{}")

      hash = description.to_hash

      has_format_version = hash.has_key?("meta") && hash["meta"].has_key?("format_version")
      expect(has_format_version).to be(false)
    end
  end

  describe "#to_json" do
    it "generates valid json" do
      description = create_test_description
      json = description.to_json

      expect(description.to_hash).to eq(JSON.parse(json))
    end
  end

  describe "#scopes" do
    it "returns a sorted list of scopes which are available in the system description" do
      description = create_test_description(name: @name, json: @description)
      expect(description.scopes).to eq(["packages", "repositories"])
    end
  end

  describe "#assert_scopes" do
    it "checks the system description for completeness" do
      full_description = create_test_description(name: @name, json: @description)
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
           Machinery::Errors::SystemDescriptionError,
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
      description = create_test_description(name: "name", json: json)

      expect {
        description.short_os_version
      }.to raise_error(Machinery::Errors::SystemDescriptionError)
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
      description = create_test_description(name: "name", json: json)

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
      description = create_test_description(name: "name", json: json)

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
      description = create_test_description(name: "name", json: json)

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
      description = create_test_description(name: "name", json: json)

      expect(description.short_os_version).to eq("sles12")
    end
  end

  describe "#scope_extracted?" do
    let(:extracted_description) {
      json = <<-EOF
        {
          "config_files": {
            "_attributes": {
              "extracted": true
            },
            "_elements": []
          }
        }
      EOF
      create_test_description(name: "name", json: json)
    }
    let(:unextracted_description) {
      json = <<-EOF
        {
          "config_files": {
            "_attributes": {
              "extracted": false
            },
            "_elements": []
          }
        }
      EOF
      create_test_description(name: "name", json: json)
    }

    it "returns true" do
      expect(extracted_description.scope_extracted?("config_files")).to be(true)
    end

    it "returns false" do
      expect(unextracted_description.scope_extracted?("config_files")).to be(false)
    end
  end

  describe "#description_path" do
    it "returns the correct path" do
      store = SystemDescriptionStore.new
      description = create_test_description(
        name: "foo",
        store: store,
        json: @description
      )

      expect(description.description_path).to eq(store.base_path + "/foo")
    end
  end

  describe ".valid_name?" do
    it "returns true for a valid name" do
      expect(SystemDescription.valid_name?("valid_name")).to be(true)
    end

    it "returns false for hidden names" do
      expect(SystemDescription.valid_name?(".invalid_name")).to be(false)
    end

    it "returns false for names with special characters" do
      expect(SystemDescription.valid_name?("invalid_$name")).to be(false)
    end
  end

  describe ".validate_name" do
    it "accepts valid name" do
      expect {
        SystemDescription.validate_name("valid_name")
      }.to_not raise_error
    end

    it "rejects hidden names" do
      expect {
        SystemDescription.validate_name(".invalid_name")
      }.to raise_error Machinery::Errors::SystemDescriptionError
    end

    it "rejects names with special characters" do
      expect {
        SystemDescription.validate_name("invalid_$name")
      }.to raise_error Machinery::Errors::SystemDescriptionError
    end
  end

  describe "#save" do
    include_context "machinery test directory"

    it "saves a SystemDescription" do
      store = SystemDescriptionStore.new(test_base_path)
      create_test_description(name: test_name, json: test_manifest, store: store).save
      descr_dir = store.description_path(test_name)
      manifest = store.manifest_path(test_name)
      content = File.read(manifest)

      expect(File.stat(descr_dir).mode & 0777).to eq(0700)
      expect(File.stat(manifest).mode & 0777).to eq(0600)
      expect(content).to eq(test_manifest)
    end

    it "keeps permissions for existing files during save" do
      store = SystemDescriptionStore.new(test_base_path)
      create_test_description(name: test_name, json: test_manifest, store: store).save

      descr_dir = store.description_path(test_name)
      File.chmod(0755, descr_dir)
      manifest = store.manifest_path(test_name)
      File.chmod(0644, manifest)

      create_test_description(json: test_manifest, store: store).save
      expect(File.stat(descr_dir).mode & 0777).to eq(0755)
      expect(File.stat(manifest).mode & 0777).to eq(0644)
    end

    it "raises Errors::SystemDescriptionInvalid if the system description name is invalid" do
      expect {
        create_test_description(name: "invalid/slash", json: test_manifest).save
      }.to raise_error(Machinery::Errors::SystemDescriptionError)
      expect {
        create_test_description(name: ".invalid_dot", json: test_manifest).save
      }.to raise_error(Machinery::Errors::SystemDescriptionError)
    end
  end

  describe "#scope_file_store" do
    it "returns scope file store" do
      description = create_test_description(store_on_disk: true)
      file_store = description.scope_file_store("my_scope")
      expect(file_store.store_name).to eq("my_scope")
      expect(file_store.base_path).to eq(description.description_path)
    end
  end

  describe "#validate_analysis_compatibility" do
    context "within a suse distro" do
      before do
        allow_any_instance_of(OsOpenSuse13_1).to receive(:architecture).and_return("x86_64")
      end

      context "with no zypper installed" do
        before do
          allow_any_instance_of(Zypper).to receive(:version).and_return(nil)
        end

        it "raises an error" do
          json = <<-EOF
            {
              "os": {
                "name": "openSUSE 13.1 (Bottle)",
                "version": "13.1 (Bottle)"
              }
            }
          EOF
          description = create_test_description(name: "name", json: json)
          expect {
            description.validate_analysis_compatibility
          }.to raise_error
        end
      end

      context "with zypper version older than 1.11.4" do
        before do
          allow_any_instance_of(Zypper).to receive(:version).and_return([0, 0, 0])
        end

        it "raises an error" do
          json = <<-EOF
            {
              "os": {
                "name": "openSUSE 13.1 (Bottle)",
                "version": "13.1 (Bottle)"
              }
            }
          EOF
          description = create_test_description(name: "name", json: json)
          expect {
            description.validate_analysis_compatibility
          }.to raise_error
        end
      end

    end

    context "within an unkown distro" do
      before do
        allow_any_instance_of(OsUnknown).to receive(:architecture).and_return("x86_64")
      end

      context "with a valid zypper version" do
        before do
          allow_any_instance_of(Zypper).to receive(:version).and_return([1, 11, 14])
        end

        it "doesn't raise" do
          json = <<-EOF
            {
              "os": {
                "name": "OS Which Will Never Exist",
                "version": "6.6"
              }
            }
          EOF
          description = create_test_description(name: "name", json: json)
          expect {
            description.validate_analysis_compatibility
          }.to_not raise_error
        end
      end
    end
  end

  describe "load methods" do
    let(:store) { system_description_factory_store }

    before(:each) do
      create_test_description(
        name: "description1",
        store_on_disk: true,
        filter_definitions: {
          "inspect" => [
            "/unmanaged_files/files/name=/opt*"
          ]
        }
      )
    end

    describe ".load" do
      it "loads a system description" do
        expect(SystemDescription.load("description1", store)).to be_a(SystemDescription)
      end

      it "validates the description by default" do
        expect_any_instance_of(Manifest).to receive(:validate).and_call_original
        expect_any_instance_of(SystemDescription).to receive(
          :validate_file_data
        ).and_call_original
        expect_any_instance_of(SystemDescription).to receive(
          :validate_format_compatibility
        ).and_call_original

        SystemDescription.load("description1", store)
      end

      it "skips data and file validation in case of the option skip_validation" do
        expect_any_instance_of(Manifest).not_to receive(:validate)
        expect_any_instance_of(SystemDescription).not_to receive(
          :validate_file_data
        )
        expect_any_instance_of(SystemDescription).to receive(
          :validate_format_compatibility
        ).and_call_original

        SystemDescription.load("description1", store, skip_validation: true)
      end

      it "skips format version validation in case of the option skip_format_compatibility" do
        expect_any_instance_of(Manifest).to receive(:validate).and_call_original
        expect_any_instance_of(SystemDescription).to receive(
          :validate_file_data
        )
        expect_any_instance_of(SystemDescription).not_to receive(
          :validate_format_compatibility
        )

        SystemDescription.load("description1", store, skip_format_compatibility: true)
      end

      it "reads the filter information" do
        description = SystemDescription.load("description1", store)

        expected = [
          "/unmanaged_files/files/name=/opt*"
        ]

        expect(description.filter_definitions("inspect")).to eq(expected)
      end
    end
  end

  describe "#set_filter_definitions" do
    subject { create_test_description(scopes: ["unmanaged_files"]) }

    it "sets the inspection filters" do
      expect(subject.to_hash["meta"]["filters"]).to be(nil)
      expected = ["/foo=bar", "/foo=baz", "/scope=filter"]

      subject.set_filter_definitions("inspect",
        Filter.new(["/foo=bar", "/foo=baz", "/scope=filter"]).to_array)
      filters = subject.to_hash["meta"]["filters"]["inspect"]
      expect(filters).to eq(expected)
    end

    it "only supports inspection filters" do
      expect {
        subject.set_filter_definitions("show", Filter.new(["/foo=bar", "/scope=filter"]).to_array)
      }.to raise_error(/not supported/)
    end
  end

  describe "#filter_definitions" do
    subject { create_test_description(scopes: ["unmanaged_files"]) }

    it "returns an empty array for commands that don't have filter definitions set" do
      expect(subject.filter_definitions("empty_command")).to eq([])
    end

    it "returns the filter definitions" do
      definitions = ["/foo=bar", "/foo=baz", "/scope=filter"]

      subject.set_filter_definitions("inspect", definitions)
      expect(subject.filter_definitions("inspect")).to eq(definitions)
    end
  end

  describe "#runs_service?" do
    let(:system_description) {
      create_test_description(json: <<-EOF)
        {
          "services": {
            "_attributes": {
              "init_system": "systemd"
            },
            "_elements": [
              {
                "name": "mysql.service",
                "state": "enabled"
              }]
          }
        }
      EOF
    }
    it "returns true when found" do
      expect(system_description.runs_service?("mysql")).to be_truthy
    end
  end

  describe "#has_file?" do
    let(:system_description) {
      SystemDescription.load!("opensuse_leap-build",
        SystemDescriptionStore.new("spec/data/descriptions"))
    }

    it "returns true when found" do
      expect(system_description.has_file?("/etc/magicapp.conf")).to be_truthy
    end
  end

  describe "#read_config" do
    let(:system_description) {
      create_test_description(json: <<-EOF)
        {
          "config_files": {
            "_attributes": {
              "extracted": true
            },
            "_elements": [
              {
                "name": "/etc/my.cnf"
              }
            ]
          }
        }
      EOF
    }
    context "when `=` assings the value" do
      it "returns the value to the right of `=`" do
        allow_any_instance_of(Machinery::SystemFile).
          to receive(:content).and_return("foo = bar")
        expect(system_description.read_config("/etc/my.cnf", "foo")).to eq("bar")
      end
    end
    context "when `:` assings the value" do
      it "returns the value to the right of `:`" do
        allow_any_instance_of(Machinery::SystemFile).
          to receive(:content).and_return(" foo: bar")
        expect(system_description.read_config("/etc/my.cnf", "foo")).to eq("bar")
      end
    end
  end
end
