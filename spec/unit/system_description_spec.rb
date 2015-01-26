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

describe SystemDescription do
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
        "format_version": 2
      }
    }'
  end

  it "returns empty JSON structure on .new" do
    data = SystemDescription.new("foo", SystemDescriptionMemoryStore.new)
    expect(data.to_json.delete(' ')).to eq(@empty_description.delete(' '))
  end

  it "provides nested accessors for data attributes" do
    data = create_test_description(name: @name, json: @description)
    expect(data.repositories.first.alias).to eq("openSUSE_13.1_OSS")
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

  describe ".from_hash" do
    it "raises InvalidSystemDescription if json input does not start with a hash" do
      class SystemDescriptionFooConfig < Machinery::Object; end
      expect {
        SystemDescription.from_hash(
          @name,
          SystemDescriptionMemoryStore.new,
          JSON.parse('[ "system-description-foo", "xxx" ]')
        )
      }.to raise_error(Machinery::Errors::SystemDescriptionIncompatible)
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
            "extracted": true
          }
        }
      EOF
      create_test_description(name: "name", json: json)
    }
    let(:unextracted_description) {
      json = <<-EOF
        {
          "config_files": {
            "extracted": false
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
    initialize_system_description_factory_store

    it "returns scope file store" do
      description = create_test_description(store_on_disk: true)
      file_store = description.scope_file_store("my_scope")
      expect(file_store.store_name).to eq("my_scope")
      expect(file_store.base_path).to eq(description.description_path)
    end
  end

  describe "#validate_analysis_compatibility" do
    it "accepts a supported os" do
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
      }.to_not raise_error
    end

    it "rejects an unsupported os" do
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
      }.to raise_error(Machinery::Errors::AnalysisFailed)
    end
  end

  describe "#validate_export_compatibility" do
    it "accepts a supported os" do
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
        description.validate_export_compatibility
      }.to_not raise_error
    end

    it "rejects an unsupported os" do
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
        description.validate_export_compatibility
      }.to raise_error(Machinery::Errors::ExportFailed)
    end
  end
end
