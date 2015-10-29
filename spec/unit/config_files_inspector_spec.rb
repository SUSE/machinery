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

describe ConfigFilesInspector do
  initialize_system_description_factory_store

  describe ".inspect" do
    let(:rpm_database) { double }
    let(:system) {
      double(
        rpm_database:                      rpm_database,
        check_requirement:                 true,
        check_retrieve_files_dependencies: true
      )
    }
    let(:name) { "systemname" }
    let(:store) { system_description_factory_store }
    let(:description) {
      SystemDescription.new(name, store)
    }
    let(:filter) { nil }

    before(:each) do
      create_test_description(json: "{}", name: name, store: store).save
    end

    subject { ConfigFilesInspector.new(system, description) }

    describe "#inspect" do
      let(:inspector) { ConfigFilesInspector.new(system, description) }
      let(:extractable_paths) {
        [
          "/etc/config",
          "/etc/linked_config",
          "/etc/config_directory",
          "/usr/share/man/man1/time.1.gz"
        ]
      }

      before(:each) do
        allow(rpm_database).to receive(:changed_files).and_return(
          [
            RpmDatabase::ChangedFile.new(
              "c",
              name:            "/etc/config",
              status:          "changed",
              changes:         ["md5"],
              package_name:    "zypper",
              package_version: "1.6.311"
            ),
            RpmDatabase::ChangedFile.new(
              "c",
              name:            "/etc/deleted_config",
              status:          "changed",
              changes:         ["deleted"],
              package_name:    "zypper",
              package_version: "1.6.311"
            ),
            RpmDatabase::ChangedFile.new(
              "c",
              name:            "/etc/linked_config",
              status:          "changed",
              changes:         ["link_path"],
              package_name:    "zypper",
              package_version: "1.6.311"
            ),
            RpmDatabase::ChangedFile.new(
              "c",
              name:            "/etc/config_directory",
              status:          "changed",
              changes:         ["user"],
              package_name:    "zypper",
              package_version: "1.6.311"
            ),
            RpmDatabase::ChangedFile.new(
              "c",
              name:            "/usr/share/man/man1/time.1.gz",
              status:          "changed",
              changes:         ["user"],
              package_name:    "man",
              package_version: "2"
            ),
            RpmDatabase::ChangedFile.new(
              "",
              name:            "/etc/other",
              status:          "changed",
              changes:         ["md5"],
              package_name:    "konsole",
              package_version: "3.4"
            )
          ]
        )
        allow(rpm_database).to receive(:get_path_data).and_return(
          "/etc/config" => {
            user:  "root",
            group: "root",
            mode:  "600",
            type:  "file"
          },
          "/etc/config_directory" => {
            user:  "root",
            group: "root",
            mode:  "600",
            type:  "dir"
          },
          "/usr/share/man/man1/time.1.gz" => {
            user:  "user",
            group: "root",
            mode:  "600",
            type:  "file"
          }
        )
      end

      context "with filters" do
        it "filters out the matching elements" do
          filter = Filter.new("/config_files/files/name=/usr/*")
          inspector.inspect(filter)
          expect(description.config_files.files.map(&:name)).
            to_not include("/usr/share/man/man1/time.1.gz")

          inspector.inspect(nil)
          expect(description.config_files.files.map(&:name)).
            to include("/usr/share/man/man1/time.1.gz")
        end
      end

      context "without filters" do
        it "returns data about modified config files when requirements are fulfilled" do
          inspector.inspect(filter)

          expect(description["config_files"].files.map(&:name)).to eq([
            "/etc/config",
            "/etc/config_directory",
            "/etc/deleted_config",
            "/etc/linked_config",
            "/usr/share/man/man1/time.1.gz"
          ])
          expect(inspector.summary).to include("5 changed configuration files")
        end

        it "returns empty when no modified config files are there" do
          expect(rpm_database).to receive(:changed_files).and_return([])

          inspector.inspect(filter)
          expected = ConfigFilesScope.new(
            extracted: false,
            files:     ConfigFileList.new
          )
          expect(description["config_files"]).to eq(expected)
        end

        it "extracts changed configuration files" do
          config_file_directory = File.join(store.description_path(name), "config_files")
          expect(system).to receive(:retrieve_files).with(extractable_paths, config_file_directory)

          inspector.inspect(filter, extract_changed_config_files: true)

          expect(inspector.summary).to include("Extracted 5 changed configuration files")
          config_file_directory = File.join(store.description_path(name), "config_files")
          expect(File.stat(config_file_directory).mode & 0777).to eq(0700)
        end

        it "keep permissions on extracted config files dir" do
          config_file_directory = File.join(store.description_path(name), "config_files")
          expect(system).to receive(:retrieve_files).with(
            extractable_paths,
            config_file_directory
          )
          FileUtils.mkdir_p(config_file_directory)
          File.chmod(0750, config_file_directory)
          File.chmod(0750, store.description_path(name))

          inspector.inspect(filter, extract_changed_config_files: true)
          expect(inspector.summary).to include("Extracted 5 changed configuration files")
          expect(File.stat(config_file_directory).mode & 0777).to eq(0750)
        end
        it "raises an error when requirements are not fulfilled" do
          allow_any_instance_of(ConfigFilesInspector).to receive(
            :check_requirements
          ).and_raise(Machinery::Errors::MissingRequirement)

          expect { inspector.inspect(filter) }.to raise_error(
            Machinery::Errors::MissingRequirement
          )
        end

        it "removes config files on inspect without extraction" do
          config_file_directory      = File.join(store.description_path(name), "config_files")
          config_file_directory_file = File.join(config_file_directory, "config_file")
          FileUtils.mkdir_p(config_file_directory)
          FileUtils.touch(config_file_directory_file)

          expect(File.exists?(config_file_directory_file)).to be true

          inspector.inspect(filter)

          expect(File.exists?(config_file_directory_file)).to be false
        end

        it "returns schema compliant data" do
          config_file_directory = File.join(store.description_path(name), "config_files")
          expect(system).to receive(:retrieve_files).with(
            extractable_paths,
            config_file_directory
          )

          inspector.inspect(filter, extract_changed_config_files: true)

          expect {
            JsonValidator.new(description.to_hash).validate
          }.to_not raise_error
        end

        it "returns sorted data" do
          config_file_directory = File.join(store.description_path(name), "config_files")
          expect(system).to receive(:retrieve_files).with(
            extractable_paths,
            config_file_directory
          )

          inspector.inspect(filter, extract_changed_config_files: true)
          names = description["config_files"].files.map(&:name)

          expect(names).to eq(names.sort)
        end
      end
    end
  end
end
