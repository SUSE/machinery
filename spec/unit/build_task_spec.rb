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

describe Machinery::BuildTask do
  initialize_system_description_factory_store

  let(:system_description) {
    create_test_description(scopes: ["os", "packages", "repositories"], store_on_disk: true)
  }
  let(:build_task) { Machinery::BuildTask.new }
  let(:output_path) { given_directory }
  let(:tmp_config_dir) { given_directory }
  let(:tmp_image_dir) { given_directory }
  let(:image_extension) { "qcow2" }
  let(:image_file) { system_description.name + ".x86_64-0.0.1.qcow2" }

  before(:each) {
    allow(Machinery::LocalSystem).to receive(:os).and_return(
      OsOpenSuse13_1.new(architecture: "x86_64")
    )
    allow(Cheetah).to receive(:run)
    allow_any_instance_of(Os).to receive(:architecture).and_return("x86_64")
    allow(Dir).to receive(:mktmpdir).
      with("machinery-config", "/tmp").and_return(tmp_config_dir)
    allow(Dir).to receive(:mktmpdir).
      with("machinery-image", "/tmp").and_return(tmp_image_dir)
    allow_any_instance_of(Machinery::SystemDescription).to receive(:validate_build_compatibility)

    FileUtils.touch(File.join(output_path, image_file))
  }

  describe "#build" do
    it "stores the kiwi config to a temporary directory" do
      build_task.build(system_description, output_path)
      expect(File.exist?(File.join(tmp_config_dir, "config.xml"))).to be(true)
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

    it "handles execution errors gracefully" do
      expect(Cheetah).to receive(:run).with("rpm", "-q", "kiwi")
      expect(Cheetah).to receive(:run).with("rpm", "-q", "kiwi-desc-vmxboot")
      expect(Cheetah).to receive(:run) { |*cmd_array|
        expect(cmd_array).to include("sudo")
        expect(cmd_array.index { |s|
          s.include?("machinery-kiwi-wrapper-script")
        }).not_to be(nil)
      }.and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))

      expect { subject.build(system_description, output_path) }.to raise_error(
        Machinery::Errors::BuildFailed, /The execution of the build script failed./
      )
    end

    it "deletes the wrapper script after usage" do
      tmp_dir = given_directory
      allow(Tempfile).to receive(:new).and_return(
        Tempfile.new("machinery-kiwi-wrapper-script", given_directory)
      )

      build_task.build(system_description, output_path)
      expect(Dir.glob(File.join(tmp_dir, "machinery-kiwi-wrapper-script*"))).to be_empty
    end

    it "raises an exception if the temporary directories are not in /tmp" do
      allow(Dir).to receive(:mktmpdir).
        with("machinery-image", "/tmp").and_return("/something/wrong/tmp/")
      expect {
        build_task.build(system_description, output_path)
      }.to raise_error(RuntimeError, /Kiwi temporary build/)
    end

    it "creates the output directory if it doesn't exist" do
      build_task.build(system_description, output_path)
      expect(Dir.exist?(output_path)).to be(true)
    end

    it "throws an error if kiwi doesn't exist" do
      allow(Machinery::LocalSystem).to receive(:validate_existence_of_packages).and_raise(
        Machinery::Errors::MissingRequirement.new(["kiwi"])
      )
      expect{
        build_task.build(system_description, output_path)
      }.to raise_error(Machinery::Errors::MissingRequirement, /kiwi/)
    end

    it "creates a yaml file in the output directory with the name in it" do
      meta_file = File.join(output_path, "machinery.meta")

      build_task.build(system_description, output_path)

      expect(File.exist?(meta_file)).to be(true)
      content = YAML.load_file(meta_file)
      expect(content[:description]).to eq(system_description.name)
      expect(content[:image_file]).to eq(image_file)
    end

    it "shows an error with path to kiwi log after failure" do
      image_path = File.join(output_path, image_file)
      FileUtils.rm(image_path)
      expect(File.exist?(image_path)).to be(false)
      expect{
        build_task.build(system_description, output_path)
      }.to raise_error(Machinery::Errors::BuildFailed, /kiwi-terminal-output.log/)
    end

    it "shows an error on non x86_64 architectures" do
      allow_any_instance_of(Os).to receive(:architecture).and_return("i586")

      expect {
        build_task.build(system_description, output_path)
      }.to raise_error(Machinery::Errors::UnsupportedArchitecture,
        /operation is not supported on architecture 'i586'/)
    end

    it "shows an error when the current user does not have access to the image directory path" do
      allow(Machinery::LocalSystem).to receive(:validate_architecture)
      allow_any_instance_of(Os).to receive(:architecture).and_return("x86_64")

      user = Machinery::CurrentUser.new.username

      expect {
        build_task.build(system_description, "/test")
      }.to raise_error(
        Machinery::Errors::BuildDirectoryCreateError,
        /'\/test' because the user '#{user}'/
      )
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
      expect(File.exist?(@wrapper_script)).to be(true)
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
