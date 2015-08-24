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

describe ContainerizeTask do
  include GivenFilesystemSpecHelpers
  use_given_filesystem

  let(:output_path) { given_directory }
  let(:containerize_task) { ContainerizeTask.new }
  let(:system_description) {
    create_test_description(json: <<-EOF)
      {
        "services": {
          "init_system": "systemd",
          "services": [
            {
              "name": "mysql.service",
              "state": "enabled"
            }]
        },
        "config_files": {
          "extracted": true,
          "files": [
            {
              "name": "/etc/my.cnf"
            }
          ]
        }
      }
    EOF
  }

  describe "#containerize" do
    let(:workloads) { Hash.new }

    it "containerize a system description" do
      expect_any_instance_of(WorkloadMapper).
        to receive(:identify_workloads).with(system_description).and_return(workloads)
      expect_any_instance_of(WorkloadMapper).
        to receive(:save).with(workloads, File.join(output_path, system_description.name))
      containerize_task.containerize(system_description, output_path)
    end
  end

  describe "#write_readme_file" do
    subject { ContainerizeTask.new }
    it "writes the README file to output dir" do
      allow($stdout).to receive(:puts)
      subject.write_readme_file(output_path)
      readme = File.join(output_path, "README.md")

      expect(File.exists?(readme)).to be(true)

      expect(File.read(readme)).to include(
        "README for Docker Containers created by Machinery"
      )
    end
  end
end
