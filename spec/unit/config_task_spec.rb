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

describe ConfigTask do
  include FakeFS::SpecHelpers
  let(:config_task) { ConfigTask.new }

  describe "#config" do
    before(:each) do
      allow(Machinery::Ui).to receive(:puts)
    end

    it "sets a bool config variable to false" do
      key = "my_config"
      allow_any_instance_of(Machinery::Config).to receive(:get).with(key).and_return(true)
      expect_any_instance_of(Machinery::Config).to receive(:set).with(key, false)
      expect_any_instance_of(Machinery::Config).to receive(:get).with(key)
      config_task.config(key, "off")
    end

    it "sets a bool config variable to true" do
      key = "my_config"
      allow_any_instance_of(Machinery::Config).to receive(:get).with(key).and_return(true)
      expect_any_instance_of(Machinery::Config).to receive(:set).with(key, true)
      expect_any_instance_of(Machinery::Config).to receive(:get).with(key)
      config_task.config(key, "true")
    end

    it "sets a string config variable" do
      key = "my_config"
      allow_any_instance_of(Machinery::Config).to receive(:get).with(key).and_return("foo")
      expect_any_instance_of(Machinery::Config).to receive(:set).with(key, "foo")
      expect_any_instance_of(Machinery::Config).to receive(:get).with(key)
      config_task.config(key, "foo")
    end

    it "sets an integer config variable" do
      key = "my_config"
      allow_any_instance_of(Machinery::Config).to receive(:get).with(key).and_return(42)
      expect_any_instance_of(Machinery::Config).to receive(:set).with(key, 21)
      expect_any_instance_of(Machinery::Config).to receive(:get).with(key)
      config_task.config(key, "21")
    end

    it "retrieves the value of a config variable" do
      key = "my_config"
      expect_any_instance_of(Machinery::Config).to receive(:get).with(key)
      config_task.config(key)
    end

    it "retrieves the values of all config variables" do
      expect_any_instance_of(Machinery::Config).to receive(:each)
      config_task.config()
    end
  end

  describe "#parse_value_string" do
    context "for default true" do
      before(:each) do
        config = Machinery::Config.new
        config.entry("configkey", default: true, description: "configtext")
        @config_task = ConfigTask.new(config)
      end

      it "parses 'true'" do
        expect(@config_task.parse_value_string("configkey", "true")).to be(true)
      end

      it "parses 'on'" do
        expect(@config_task.parse_value_string("configkey", "on")).to be(true)
      end

      it "parses 'false'" do
        expect(@config_task.parse_value_string("configkey", "false")).to be(false)
      end

      it "parses 'off'" do
        expect(@config_task.parse_value_string("configkey", "off")).to be(false)
      end

      it "raises an error if wrong type of input is given" do
        expect {
          @config_task.parse_value_string("configkey", 42)
        }.to raise_error(Machinery::Errors::MachineryError, /valid variable of type boolean/)
      end
    end

    context "for default false" do
      before(:each) do
        config = Machinery::Config.new
        config.entry("configkey", default: false, description: "configtext")
        @config_task = ConfigTask.new(config)
      end

      it "parses 'true'" do
        expect(@config_task.parse_value_string("configkey", "true")).to be(true)
      end

      it "parses 'on'" do
        expect(@config_task.parse_value_string("configkey", "on")).to be(true)
      end

      it "parses 'false'" do
        expect(@config_task.parse_value_string("configkey", "false")).to be(false)
      end

      it "parses 'off'" do
        expect(@config_task.parse_value_string("configkey", "off")).to be(false)
      end

      it "raises an error if wrong type of input is given" do
        expect {
          @config_task.parse_value_string("configkey", 42)
        }.to raise_error(Machinery::Errors::MachineryError, /valid variable of type boolean/)
      end
    end

    context "for default string" do
      before(:each) do
        config = Machinery::Config.new
        config.entry("configkey", default: "text", description: "configtext")
        @config_task = ConfigTask.new(config)
      end

      it "parses string 'true'" do
        expect(@config_task.parse_value_string("configkey", "true")).to eq("true")
      end
    end
  end
end
