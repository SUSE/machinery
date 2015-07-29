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

describe Machinery::Config do
  include FakeFS::SpecHelpers
  subject { Machinery::Config.new }

  it "works with keys with '-'s" do
    subject.entry("config-key", default: "configvalue", description: "configtext")

    subject.set("config-key", "newconfigvalue")
    expect(subject.get("config-key")).to eq("newconfigvalue")
    expect(subject.config_key).to eq("newconfigvalue")

    keys = []
    subject.each { |key, _value| keys << key }
    expect(keys).to include("config-key")
  end

  it "uses the default config-path if nothing is specified" do
    config = Machinery::Config.new
    expect(config.file).to eq(Machinery::DEFAULT_CONFIG_FILE)
  end

  it "uses the config-path specified by initialize" do
    config = Machinery::Config.new(config_file_path)
    expect(config.file).to eq(config_file_path)
  end

  describe "#get" do
    it "returns the default value" do
      subject.entry("configkey", default: "configvalue", description: "configtext")

      expect(subject.get("configkey")).to eq("configvalue")
    end

    it "raises an error when a config is unknown" do
      expect {
        value = subject.get("unknownkey")
      }.to raise_error(Machinery::Errors::UnknownConfig)
    end
  end

  describe "#set" do
    it "sets a config value" do
      subject.entry("configkey", default: "configvalue", description: "configtext")

      subject.set("configkey", "newconfigvalue")
      expect(subject.get("configkey")).to eq("newconfigvalue")
    end

    it "raises an error when a config is unknown" do
      expect {
        subject.set("unknown_key", "unknwon_config_value")
      }.to raise_error(Machinery::Errors::UnknownConfig)
    end

    it "raises an error when config entry containing a string is set to bool" do
      subject.entry("string", default: "foo", description: "string")
      expect {
        subject.set("string", false)
      }.to raise_error(Machinery::Errors::MachineryError)
    end

    it "raises an error when config entry containing a int is set to string" do
      subject.entry("int", default: 42, description: "int")
      expect {
        subject.set("int", "42")
      }.to raise_error(Machinery::Errors::MachineryError)
    end

    it "raises an error when config entry containing a bool is set to string" do
      subject.entry("bool", default: false, description: "int")
      expect {
        subject.set("bool", "false")
      }.to raise_error(Machinery::Errors::MachineryError)
    end
  end

  describe "#each" do
    it "returns all config entries" do
      subject.entry("foo", default: "foovalue", description: "footext")
      subject.entry("bar", default: "barvalue", description: "bartext")

      expected = {
        "foo" => { value: "foovalue", description: "footext" },
        "bar" => { value: "barvalue", description: "bartext" }
      }

      expect(subject.each).to include(*expected)
    end
  end

  describe "#save" do
    it "writes the config to the file when the set method is called" do
      allow_any_instance_of(Machinery::Config).to receive(:define_entries)
      subject.entry("configkey", default: false, description: "configtext")

      subject.set("configkey", true)
      expect(File.readlines(Machinery::DEFAULT_CONFIG_FILE)).to eq(["---\n", "configkey: true\n"])

      subject.set("configkey", false)
      expect(File.readlines(Machinery::DEFAULT_CONFIG_FILE)).to eq(["---\n", "configkey: false\n"])
    end

    it "writes the config to the file when the generated accessors are called" do
      allow_any_instance_of(Machinery::Config).to receive(:define_entries)
      subject.entry("configkey", default: false, description: "configtext")

      subject.configkey = true
      expect(File.readlines(Machinery::DEFAULT_CONFIG_FILE)).to eq(["---\n", "configkey: true\n"])

      subject.configkey = false
      expect(File.readlines(Machinery::DEFAULT_CONFIG_FILE)).to eq(["---\n", "configkey: false\n"])
    end
  end

  describe "#apply_custom_config" do
    it "applies the custom values from the config file" do
      config_file=File.join(Machinery::ROOT, "spec/data/machinery.config")
      FakeFS::FileSystem.clone(config_file)
      subject.entry("configkey", default: true, description: "configtext")
      subject.send(:apply_custom_config, config_file)

      expect(subject.get("configkey")).to eq(false)
    end
  end

  describe "native accessor" do
    it "gets the default value" do
      subject.entry("configkey", default: "configvalue", description: "configtext")
      expect(subject.configkey).to eq("configvalue")
    end

    it "sets and gets values" do
      subject.entry("configkey", default: "configvalue", description: "configtext")

      subject.configkey = "newvalue"
      expect(subject.configkey).to eq("newvalue")
    end
  end
end
