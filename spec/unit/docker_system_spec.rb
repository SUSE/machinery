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

describe Machinery::DockerSystem do
  include GivenFilesystemSpecHelpers
  use_given_filesystem

  let(:false_container_id) { "0a0a0a0a0a0a" }
  let(:valid_container_id) { "076f46c1bef1" }
  let(:instance) { "12345" }
  subject { Machinery::DockerSystem.new(valid_container_id).tap(&:start) }

  before(:each) do
    allow(Machinery::LoggedCheetah).
      to receive(:run).with("docker", "inspect", false_container_id).and_raise
    allow(Machinery::LoggedCheetah).
      to receive(:run).with("docker", "inspect", valid_container_id)
    allow(Machinery::LoggedCheetah).
      to receive(:run).with("docker", "run", any_args).and_return(instance)
    allow(subject).to receive(:stop)
  end

  describe "#initialize" do
    it "raises an error if image id is invalid" do
      expect {
        Machinery::DockerSystem.new(false_container_id)
      }.to raise_error(Machinery::Errors::InspectionFailed)
    end

    it "does not raise an error if image id is valid" do
      expect {
        Machinery::DockerSystem.new(valid_container_id)
      }.not_to raise_error
    end
  end

  describe "#run_command" do
    it "runs the command using docker exec" do
      expect(Machinery::LoggedCheetah).
        to receive(:run).with(
          "docker",
          "exec",
          "--user=root",
          "-i",
          "12345",
          "bash -c python"
        )

      subject.run_command("bash -c python")
    end
  end

  describe "#inject_file" do
    it "injects the file using docker cp" do
      expect(Machinery::LoggedCheetah).
        to receive(:run).with("docker", "cp", "/tmp/foo", "12345:/tmp")

      subject.inject_file("/tmp/foo", "/tmp")
    end
  end

  describe "#retrieve_files" do
    it "extracts the files using docker cp" do
      expect(Machinery::LoggedCheetah).
        to receive(:run).with("docker", "cp", "12345:/tmp/foo", "/tmp/foo")
      expect(Machinery::LoggedCheetah).
        to receive(:run).with("docker", "cp", "12345:/tmp/bar", "/tmp/bar")
      expect(Machinery::LoggedCheetah).
        to receive(:run).with("chmod", any_args).twice

      subject.retrieve_files(["/tmp/foo", "/tmp/bar"], "/")
    end
  end

  describe "#create_archive" do
    it "extracts the archive using MachineryHelper" do
      output_dir = given_dummy_file
      expect_any_instance_of(MachineryHelper).to receive(:run_helper_subcommand)

      subject.create_archive(["/tmp/foo", "/tmp/bar"], output_dir)
    end
  end
end
