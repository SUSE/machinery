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

describe WorkloadMapper do
  include GivenFilesystemSpecHelpers
  use_given_filesystem

  before(:each) do
    allow_any_instance_of(Machinery::SystemFile).
      to receive(:content).and_return(File.read(config_file_path))
  end

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
  let(:output_path) { given_directory }
  let(:mapper_path) { given_directory_from_data "mapper" }
  let(:docker_path) { given_directory_from_data "docker" }

  let(:workloads) { YAML::load(File.read(File.join(docker_path, "workloads.yml"))) }
  let(:config_file_path) { File.join(mapper_path, "my.cnf") }

  describe "#save" do
    it "creates a folder with a docker-compose.yml and images" do
      subject.save(workloads, output_path)
      expect(File.read(File.join(output_path, "docker-compose.yml"))).
        to include(File.read(File.join(docker_path, "docker-compose.yml")))
      expect(File.exists?(File.join(output_path, "mariadb", "Dockerfile"))).
        to be_truthy
    end
  end

  describe "#compose_service" do
    let(:expected_node) {
      {
        "db" => {
          "build" => "./mariadb",
          "environment" => {
            "MYSQL_USER" => "portus",
            "MYSQL_PASS" => "portus"
          }
        }
      }
    }
    let(:workload) { "mariadb" }
    let(:config) {
      {
        "service" => "db",
        "parameters" => {
          "user" => "portus",
          "password" => "portus"
        }
      }
    }

    it "returns a valid compose node" do
      expect(subject.compose_service(workload, config)).to eq(expected_node)
    end
  end

  describe "#identify_workloads" do
    it "returns a list of workloads" do
      expect(subject.identify_workloads(system_description)).
        to have_key("mariadb")
    end
  end

  describe "#fill_in_template" do
    let(:parameters) { { "symbol" => "value" } }

    context "when it finds a symbol" do
      let(:template) { { "service" => { "key" => :symbol } } }
      let(:filled_in_template) { { "service" => { "key" => "value" } } }

      it "replaces it with a value" do
        expect(subject.fill_in_template(template, parameters)).to eq(filled_in_template)
      end
    end

    context "when it finds a hash" do
      let(:template) { { "service" => { "hash" => { "key" => :symbol } } } }
      let(:filled_in_template) { { "service" => { "hash" => { "key" => "value" } } } }
      it "replaces it with a value" do
        expect(subject.fill_in_template(template, parameters)).to eq(filled_in_template)
      end
    end
  end
end
