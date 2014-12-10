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

describe BuildTask do
  include FakeFS::SpecHelpers

  let(:system_description) {
    create_test_description(json: <<-EOF, store: SystemDescriptionStore.new)
      {
        "packages": [
          {
            "name": "kernel-desktop",
            "version": "3.7.10",
            "release": "1.0",
            "arch": "x86_64",
            "vendor": "SUSE LINUX Products GmbH, Nuernberg, Germany",
            "checksum": "2a3d5b29179daa1e65e391d0a0c1442d"
          }
        ],
        "repositories": [
          {
            "alias": "nodejs",
            "name": "nodejs",
            "type": "rpm-md",
            "url": "http://download.opensuse.org/repositories/devel:/languages:/nodejs/openSUSE_13.1/"
          }
        ],
        "os": {
          "name": "SUSE Linux Enterprise Server 11",
          "version": "11 SP3",
          "architecture": "x86_64"
        }
      }
    EOF
  }
  let(:build_task) { BuildTask.new }
  let(:output_path) { "/tmp/output" }
  let(:tmp_config_dir) { "/tmp/machinery-config" }
  let(:tmp_image_dir) { "/tmp/machinery-image" }
  let(:image_extension) { "qcow2" }
  let(:image_file) { system_description.name + ".x86_64-0.0.1.qcow2" }

  before(:each) {
    allow(LocalSystem).to receive(:os).and_return(OsOpenSuse13_1.new)

    allow(Cheetah).to receive(:run)

    Dir.mkdir("/tmp")

    FileUtils.mkdir_p(output_path)
    FileUtils.touch(File.join(output_path, image_file))

    FakeFS::FileSystem.clone(File.join(Machinery::ROOT, "export_helpers"))
    FakeFS::FileSystem.clone(File.join(
      Machinery::ROOT, "helpers", "filter-packages-for-build.yaml")
    )
  }

  describe "#build" do
    let(:tmp_config_dir) { Dir["/tmp/machinery-config*"].first }
    let(:tmp_image_dir) { Dir["/tmp/machinery-img*"].first }

    it "stores the kiwi config to a temporary directory" do
      build_task.build(system_description, output_path)
      expect(File.exists?(File.join(tmp_config_dir, "config.xml"))).to be(true)
    end

    it "calls the kiwi wrapper script with sudo to build the image" do
      expect(Cheetah).to receive(:run).with("rpm", "-q", "kiwi")
      expect(Cheetah).to receive(:run).with("rpm", "-q", "kiwi-desc-vmxboot")
      expect(Cheetah).to receive(:run) { |*cmd_array|
        expect(cmd_array).to include("sudo")
        expect(cmd_array.index{ |s|
          s.include?("machinery-kiwi-wrapper-script")
        }).not_to be(nil)
      }

      build_task.build(system_description, output_path)
    end

    it "deletes the wrapper script after usage" do
      build_task.build(system_description, output_path)
      expect(Dir.glob("/tmp/machinery-kiwi-wrapper-script*")).to be_empty
    end

    it "raises an exception if the temporary directories are not in /tmp" do
      correct_path = "/tmp/machinery-config-test"
      expect(Dir).to receive(:mktmpdir).
        with("machinery-config", "/tmp").and_return(correct_path)
      Dir.mkdir(correct_path)

      expect(Dir).to receive(:mktmpdir).
        with("machinery-image", "/tmp").and_return("/something/wrong/tmp/")
      expect {
        build_task.build(system_description, output_path)
      }.to raise_error(RuntimeError, /Kiwi temporary build/)
    end

    it "creates the output directory if it doesn't exist" do
      build_task.build(system_description, output_path)
      expect(Dir.exists?(output_path)).to be(true)
    end

    it "throws an error if kiwi doesn't exist" do
      allow(LocalSystem).to receive(:validate_existence_of_package).and_raise(Machinery::Errors::MissingRequirement.new("kiwi"))
      expect{
        build_task.build(system_description, output_path)
      }.to raise_error(Machinery::Errors::MissingRequirement, /kiwi/)
    end

    it "creates a yaml file in the output directory with the name in it" do
      meta_file = File.join(output_path, "machinery.meta")

      build_task.build(system_description, output_path)

      expect(File.exists?(meta_file)).to be(true)
      content = YAML.load_file(meta_file)
      expect(content[:description]).to eq(system_description.name)
      expect(content[:image_file]).to eq(image_file)
    end

    it "shows an error with path to kiwi log after failure" do
      image_path = File.join(output_path, image_file)
      FileUtils.rm(image_path)
      expect(File.exists?(image_path)).to be(false)
      expect{
        build_task.build(system_description, output_path)
      }.to raise_error(Machinery::Errors::BuildFailed, /kiwi-terminal-output.log/)
    end

    it "shows the unmanaged file filters at the beginning" do
      system_description.initialize_file_store("unmanaged_files")
      system_description["unmanaged_files"] = {}

      expect(Machinery::Ui).to receive(:puts).with("\nUnmanaged files following these patterns are not added to the built image:")
      expect(Machinery::Ui).to receive(:puts) { |s|
        expect(s).to include("var/lib/rpm")
      }
      allow(Machinery::Ui).to receive(:puts)
      build_task.build(system_description, output_path)
    end
  end

  describe "#write_kiwi_wrapper" do

    before(:each) {
      # the temporary file will be deleted if the Tempfile object is freed
      # so keeping it as a instance variable
      @wrapper_object = build_task.write_kiwi_wrapper(tmp_config_dir,
        tmp_image_dir, output_path, image_extension)
      @wrapper_script = @wrapper_object.path()
    }

    it "returns a Tempfile object" do
      expect(
        build_task.write_kiwi_wrapper(tmp_config_dir, tmp_image_dir,
          output_path, image_extension)
      ).to be_a(Tempfile)
    end

    it "generates a wrapper bash script" do
      lines = File.read(@wrapper_script).split("\n")
      expect(File.exists?(@wrapper_script)).to be(true)
      expect(lines.first).to eq("#!/bin/bash")
    end

    it "marks the script as executable" do
      expect(File.executable?(@wrapper_script)).to be(true)
    end
  end

  describe "#kiwi_wrapper" do
    it "generates a script to build and clean up later on" do
      script = build_task.kiwi_wrapper(tmp_config_dir, tmp_image_dir,
        output_path, image_extension)
      expect(script).to include("kiwi")
      expect(script).to include("mv")
      expect(script).to include("rm")
      expect(script).to include("rm -rf '#{tmp_config_dir}'\n")
      expect(script).to include("rm -rf '#{tmp_image_dir}'\n")

      script.split("\n").each do |s|
        # it runs kiwi build with ticks around the directories
        if s.include?("kiwi ")
          expect(s).to include("--build '#{tmp_config_dir}'")
          expect(s).to include("--destdir '#{tmp_image_dir}'")
        end

        # it moves the qcow2 image to the output path
        if s.include?("mv ")
          expect(s).to include(
            "#{tmp_image_dir}/'*.#{image_extension} '#{output_path}'")
        end
      end
    end
  end
end
