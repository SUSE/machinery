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

describe DeployTask do
  include FakeFS::SpecHelpers

  let(:deploy_task) { DeployTask.new }
  let(:system_description) {
    create_test_description(
      scopes: ["os", "repositories", "packages"], name: "test", store: SystemDescriptionStore.new
    )
  }

  let(:cloud_config_file) { "/example-openrc.sh" }
  let(:tmp_image_dir) { "/tmp/test-image2014" }
  let(:image_dir) { "/image" }

  before(:each) do
    allow_any_instance_of(Kernel).to receive(:system)
    allow(LocalSystem).to receive(:os).and_return(OsOpenSuse13_1.new)
    allow_any_instance_of(Os).to receive(:architecture).and_return("x86_64")
    allow(LocalSystem).to receive(:validate_existence_of_package)
    allow(Dir).to receive(:mktmpdir).and_return(tmp_image_dir)
    FakeFS::FileSystem.clone("spec/data/deploy/", "/")
  end

  describe "#deploy" do
    it "runs a temporary build if no option image_dir is provided" do
      expect_any_instance_of(BuildTask).to receive(:build)
      expect(FileUtils).to receive(:rm_rf).with(tmp_image_dir)
      deploy_task.deploy(system_description, cloud_config_file)
    end

    it "does not build the image if the option image_dir is provided" do
      expect_any_instance_of(BuildTask).not_to receive(:build)
      expect(FileUtils).not_to receive(:rm_rf)
      deploy_task.deploy(system_description, cloud_config_file, image_dir: image_dir)
    end

    it "sources the cloud-config and calls glance with the options" do
      expect(deploy_task).to receive(:system).with(
        "sh -c '. #{cloud_config_file} && /usr/bin/glance image-create --name=test" \
        " --disk-format=qcow2 --container-format=bare" \
        " --file=/image/test.x86_64-0.0.1.qcow2'"
      )
      deploy_task.deploy(system_description, cloud_config_file, image_dir: image_dir)
    end

    it "escapes image names with spaces when calling glance" do
      FileUtils.cp_r("/image", "/image with spaces")
      expect(deploy_task).to receive(:system) { |s|
        expect(s).to include("image\\ with\\ spaces")
      }
      deploy_task.deploy(system_description, cloud_config_file, image_dir: "/image with spaces", insecure: true)
    end

    it "calls glance with --insecure if --insecure is used" do
      expect(deploy_task).to receive(:system) { |s|
        expect(s).to include("--insecure")
      }
      deploy_task.deploy(system_description, cloud_config_file, image_dir: image_dir, insecure: true)
    end

    it "checks if glance is missing" do
      expect(LocalSystem).to receive(:validate_existence_of_package) { |*s|
        expect(s).to include("python-glanceclient")
      }
      deploy_task.deploy(system_description, cloud_config_file, image_dir: image_dir)
    end

    it "raises an exception if the provided image-dir doesn't exist"  do
      image_dir = "/tmp/doesnotexist"
      expect(File.exists?(image_dir)).to be(false)
      expect{
        deploy_task.deploy(system_description, cloud_config_file, image_dir: "/tmp/doesnotexist")
      }.to raise_error(Machinery::Errors::DeployFailed, /image dir/)
    end

    it "raises an exception if system description doesn't equal the meta data" do
      expect{
        deploy_task.deploy(system_description, cloud_config_file, image_dir: "/wrong_description_name")
      }.to raise_error(Machinery::Errors::MissingRequirement, /build from the provided system description/)
    end

    it "raises an exception if the image mentioned in the meta data doesn't exist" do
      expect{
        deploy_task.deploy(system_description, cloud_config_file, image_dir: "/image_is_missing")
      }.to raise_error(Machinery::Errors::DeployFailed, /image file '.*' does not exist/)
    end

    it "raises an exception if the cloud config file is missing" do
      expect{
        deploy_task.deploy(system_description, "/tmp/doesnotexist.sh", image_dir: image_dir)
      }.to raise_error(Machinery::Errors::DeployFailed, /cloud config file.*could not be found/)
    end

    it "shows an error on non x86_64 architectures" do
      allow_any_instance_of(Os).to receive(:architecture).and_return("i586")
      expect {
        deploy_task.deploy(system_description, cloud_config_file, image_dir: image_dir)
      }.to raise_error(Machinery::Errors::IncompatibleHost,
        /operation is not supported on architecture 'i586'/)
    end

    it "shows an error when the system description's architecture is not supported" do
      allow(LocalSystem).to receive(:validate_architecture)
      allow_any_instance_of(Os).to receive(:architecture).and_return("i586")
      expect {
        deploy_task.deploy(system_description, cloud_config_file)
      }.to raise_error(Machinery::Errors::BuildFailed, /architecture/)
    end
  end
end
