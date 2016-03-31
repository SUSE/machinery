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
          "_attributes": {
            "init_system": "systemd"
          },
          "_elements": [
            {
              "name": "mysql.service",
              "state": "enabled"
            }]
        },
        "changed_config_files": {
          "_attributes": {
            "extracted": true
          },
          "_elements": [
            {
              "name": "/etc/my.cnf"
            }
          ]
        },
        "unmanaged_files": {
          "_attributes": {
            "extracted": true
          },
          "_elements": [
            {
              "name": "/foo/bar/",
              "type": "dir",
              "user": "superuser",
              "group": "users",
              "size": 21084193,
              "mode": "755",
              "files": 718
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

      yaml = YAML.load_file(File.join(output_path, "docker-compose.yml"))
      expect(yaml["db"]["build"]).to eq("./mariadb")
      expect(yaml["db"]["environment"]["DB_USER"]).to eq("portus")
      expect(yaml["db"]["environment"]["DB_PASS"]).to eq("portus")

      expect(
        File.exist?(File.join(output_path, "mariadb", "Dockerfile"))
      ).to be_truthy
    end
  end

  describe "#extract" do
    let(:output_path) { given_directory }
    let(:workloads) {
      {
        "foo_workload" => {
          "data" => {
            "/foo/bar/" => "/sub/path"
          }
        }
      }
    }

    it "extracts the related workload data" do
      allow_any_instance_of(UnmanagedFilesScope).to receive(:export_files_as_tarballs)
      allow_any_instance_of(WorkloadMapper).to receive(
        :copy_workload_changed_config_files
      ).and_return(true)

      expect(Cheetah).to receive(:run).with("tar", "zxf", /.*\/foo\/bar\.tgz/, "-C",
                                            /#{output_path}\/foo_workload\/sub\/path/, /--strip=\d/)
      subject.extract(system_description, workloads, output_path)
    end
  end

  describe "#compose_service" do
    let(:expected_node) {
      {
        "db" => {
          "build" => "./mariadb",
          "volumes" => ["./mariadb/data:/var/lib/mysql"],
          "environment" => {
            "DB_USER" => "username",
            "DB_PASS" => "secret",
            "DB_NAME" => "mydb"
          }
        }
      }
    }
    let(:workload) { "mariadb" }
    let(:config) {
      {
        "service" => "db",
        "parameters" => {
          "user" => "username",
          "password" => "secret",
          "name" => "mydb"
        }
      }
    }

    it "returns a valid compose node" do
      expect(subject.compose_service(workload, config)).to eq(expected_node)
    end
  end

  describe "#identify_workloads" do
    context "when one of the required scopes is missing" do
      let(:system_description) { create_test_description }

      it "raises an error" do
        expect {
          subject.identify_workloads(system_description)
        }.to raise_error(
          Machinery::Errors::SystemDescriptionError,
          /The system description misses the following scopes: .*/
        )
      end
    end

    context "when one of the required scopes was not extracted" do
      let(:system_description) {
        create_test_description(json: <<-EOF)
        {
          "services": {
            "_attributes": {
              "init_system": "systemd"
            },
            "_elements": []
          },
          "changed_config_files": {
            "_attributes": {
              "extracted": false
            },
            "_elements": []
          },
          "unmanaged_files": {
            "_attributes": {
              "extracted": false
            },
            "_elements": []
          }
        }
      EOF
      }
      it "raises an error" do
        expect {
          subject.identify_workloads(system_description)
        }.to raise_error(
          Machinery::Errors::SystemDescriptionError,
          /Required scope: '.*' was not extracted\. Can't continue\./
        )
      end
    end

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

  describe "#link_compose_services" do
    let(:unlinked_services) {
      {
        "db" => {
          "environment" => {
            "DB_VAR_1" => 1,
            "DB_VAR_2" => 2
          }
        },
        "web" => {
          "links" => ["db"]
        }
      }
    }

    let(:unlinked_services_one_missing) {
      {
        "web" => {
          "links" => ["db"]
        }
      }
    }

    let(:linked_services) {
      {
        "db" => {
          "environment" => {
            "DB_VAR_1" => 1,
            "DB_VAR_2" => 2
          }
        },
        "web" => {
          "links" => ["db"],
          "environment" => {
            "DB_VAR_1" => 1,
            "DB_VAR_2" => 2
          }
        }
      }
    }

    context "if the services which are intended to link are detected" do
      it "adds the environment variables to the linked workload" do
        subject.link_compose_services(unlinked_services)
        expect(unlinked_services).to eq(linked_services)
      end
    end

    context "if the services which are intended to link are not detected" do
      it "throws an error which identifies the failed linking" do
        expect {
          subject.link_compose_services(unlinked_services_one_missing)
        }.to raise_error(
          Machinery::Errors::ComposeServiceLink,
          /Could not detect 'db', which is referenced by 'web'./
          )
      end
    end
  end
end
