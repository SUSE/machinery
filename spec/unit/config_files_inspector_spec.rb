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
  describe ".inspect" do
    include FakeFS::SpecHelpers

    let(:system) { double }
    let(:name) { "systemname" }
    let(:store) { SystemDescriptionStore.new }
    let(:description) {
      SystemDescription.new(name, store)
    }
    let(:filter) { nil }

    before(:each) do
      create_test_description(json: "{}", name: name, store: store).save
      FakeFS::FileSystem.clone("schema/")
    end

    let(:rpm_qa_output_test1) {
      <<-EOF
texlive-metalogo-2013.72.0.0.12svn18611
psmisc-22.20
texlive-bbcard-2013.72.svn19440
open-iscsi-2.0.873
/etc/iscsi/ifaces/iface.example
/etc/iscsi/iscsid.conf
/usr/lib/systemd/system/iscsi.service
/usr/lib/systemd/system/iscsid.service
apache2-2.4.6
/etc/apache2/charset.conv
/etc/apache2/default-server.conf
/etc/apache2/default-vhost-ssl.conf
/etc/apache2/default-vhost.conf
/etc/apache2/errors.conf
yast2-pkg-bindings-3.1.1
EOF
    }
    let(:rpm_qa_output_test2) {
      <<-EOF
texlive-metalogo-2013.72.0.0.12svn18611
psmisc-22.20
texlive-bbcard-2013.72.svn19440
yast2-pkg-bindings-3.1.1
xml-commons-1.3.04
/etc/java/resolver/CatalogManager.properties
EOF
    }
    let(:rpm_qa_output_test3) {
      <<-EOF
texlive-metalogo-2013.72.0.0.12svn18611
psmisc-22.20
texlive-bbcard-2013.72.svn19440
open-iscsi-2.0.873
/etc/iscsi/ifaces/iface.example
/etc/iscsi/iscsid.conf
/usr/lib/systemd/system/iscsi.service
/usr/lib/systemd/system/iscsid.service
apache2-2.4.6
/etc/apache2/charset.conv
/etc/apache2/default-server.conf
/etc/apache2/default-vhost-ssl.conf
/etc/apache2/default-vhost.conf
/etc/apache2/errors.conf
yast2-pkg-bindings-3.1.1
apache2-2.4.6
/etc/apache2/listen.conf
EOF
    }
    let(:rpm_v_apache_output) {
      <<-EOF
S.5....T.  c /etc/apache2/default-server.conf
..5....T.  c /etc/apache2/listen.conf
S.5....T.  c /etc/sysconfig/SuSEfirewall2.d/services/apache2
missing    c /usr/share/info/dir
S.5....T.    /etc/sysconfig/ignore_me_cause_im_not_a_config_file
.........  c /usr/share/man/man1/time.1.gz (replaced)
EOF
    }
    let(:rpm_v_openiscsi_output) {
      <<-EOF
SM5..UGT.  c /etc/iscsi/iscsid.conf
EOF
    }
    let(:ls_fn_output) {
      <<-EOF
-rw-r--r-- 1 0 0 3763 Mar 27  2013 /etc/apache2/default-server.conf
-rw-r--r-- 1 0 0 1053 Mar 27  2013 /etc/apache2/listen.conf
-rw-r--r-- 1 0 0 361 Mar 27  2013 /etc/sysconfig/SuSEfirewall2.d/services/apache2
-rw-r--r-- 1 0 0 12024 Jun  6  2013 /etc/iscsi/iscsid.conf
EOF
    }
    let(:stat_output) {
      <<-EOF
644:root:root:0:0:/etc/apache2/default-server.conf
6644:root:root:0:0:/etc/apache2/listen.conf
644:root:root:0:0:/etc/sysconfig/SuSEfirewall2.d/services/apache2
4700:nobody:nobody:65534:65533:/etc/iscsi/iscsid.conf
644:root:root:0:0:/usr/share/man/man1/time.1.gz
EOF
    }
    let(:config_paths) {
      [
        "/etc/apache2/default-server.conf",
        "/etc/apache2/listen.conf",
        "/etc/sysconfig/SuSEfirewall2.d/services/apache2",
        "/usr/share/man/man1/time.1.gz",
        "/etc/iscsi/iscsid.conf"
      ]
    }
    let(:base_cmdline) {
      ["rpm", "-V", "--nodeps", "--nodigest", "--nosignature",
       "--nomtime", "--nolinkto", "--noscripts"]
    }
    let(:expected_package_list) { ["apache2-2.4.6", "open-iscsi-2.0.873"] }

    subject { ConfigFilesInspector.new(system, description) }

    def stub_stat_commands(system, files, stats_output)
      allow(system).to receive(:run_command).with(
        "stat", "--printf", "%a:%U:%G:%u:%g:%n\\n", *files,
        stdout: :capture
      ).and_return(stats_output)
    end

    describe "check requirements" do
      before(:each) do
        expect(system).to receive(:check_requirement).with("rpm", "--version")
        expect(system).to receive(:check_requirement).with("stat", "--version")
      end

      it "returns true if requirements are fulfilled" do
        requirements_fulfilled = subject.check_requirements(false)
        expect(requirements_fulfilled).equal?(true)
      end

      it "returns true if requirements are fulfilled for extraction" do
        expect(system).to receive(:check_requirement).with("rsync", "--version")
        requirements_fulfilled = subject.check_requirements(true)
        expect(requirements_fulfilled).equal?(true)
      end
    end

    describe "#packages_with_config_files" do
      let(:package_list) { subject.packages_with_config_files }

      def stub_rpm_output(system, rpm_qa_output_test)
        expect(system).to receive(:run_command).with(
          "rpm", "-qa", "--configfiles", "--queryformat",
          "%{NAME}-%{VERSION}\n", stdout: :capture
        ).and_return(rpm_qa_output_test)
      end

      it "returns a list of packages with config files" do
        stub_rpm_output(system, rpm_qa_output_test1)
        expect(package_list).to match_array expected_package_list
      end

      it "returns a unique list of packages with config files" do
        stub_rpm_output(system, rpm_qa_output_test3)
        expect(package_list).to match_array expected_package_list
      end

      it "returns a empty list when no packages contain config files" do
        stub_rpm_output(system, "")
        expect(package_list).to match_array []
      end
    end

    describe "#config_file_changes" do
      it "returns a list of changed config files" do
        apache_config_1 = ConfigFile.new(
          name: "/etc/apache2/default-server.conf",
          package_name: "apache2",
          package_version: "2.4.6",
          status: "changed",
          changes: ["size", "md5", "time"]
        )

        apache_config_2 = ConfigFile.new(
          name: "/etc/apache2/listen.conf",
          package_name: "apache2",
          package_version: "2.4.6",
          status: "changed",
          changes: ["md5", "time"]
        )

        apache_config_3 = ConfigFile.new(
          name: "/etc/sysconfig/SuSEfirewall2.d/services/apache2",
          package_name: "apache2",
          package_version: "2.4.6",
          status: "changed",
          changes: ["size", "md5", "time"]
        )

        apache_config_4 = ConfigFile.new(
          name: "/usr/share/info/dir",
          package_name: "apache2",
          package_version: "2.4.6",
          status: "changed",
          changes: ["deleted"]
        )

        apache_config_5 = ConfigFile.new(
          name: "/usr/share/man/man1/time.1.gz",
          package_name: "apache2",
          package_version: "2.4.6",
          status: "changed",
          changes: ["replaced"]
        )

        expected_apache_config_file_data = [
          apache_config_1, apache_config_2, apache_config_3, apache_config_4, apache_config_5
        ]

        expect(system).to receive(:run_script).with(
          "changed_files.sh", "--",
          "config-files",
          "apache2-2.4.6",
          stdout: :capture,
        ).and_return(rpm_v_apache_output)

        config_file_list = subject.config_file_changes("apache2-2.4.6")

        expect(config_file_list).to eq expected_apache_config_file_data
      end
    end

    describe "#inspect" do
      let(:inspector) { ConfigFilesInspector.new(system, description) }

      before(:each) do
        apache_config_1 = ConfigFile.new(
          name: "/etc/apache2/default-server.conf",
          package_name: "apache2",
          package_version: "2.4.6",
          status: "changed",
          changes: ["size", "md5", "time"]
        )

        apache_config_2 = ConfigFile.new(
          name: "/etc/apache2/listen.conf",
          package_name: "apache2",
          package_version: "2.4.6",
          status: "changed",
          changes: ["md5", "time"]
        )

        apache_config_3 = ConfigFile.new(
          name: "/etc/sysconfig/SuSEfirewall2.d/services/apache2",
          package_name: "apache2",
          package_version: "2.4.6",
          status: "changed",
          changes: ["size", "md5", "time"]
        )

        apache_config_4 = ConfigFile.new(
          name: "/usr/share/info/dir",
          package_name: "apache2",
          package_version: "2.4.6",
          status: "changed",
          changes: ["deleted"]
        )

        apache_config_5 = ConfigFile.new(
          name: "/usr/share/man/man1/time.1.gz",
          package_name: "apache2",
          package_version: "2.4.6",
          status: "changed",
          changes: ["replaced"]
        )

        iscsi_config_1 = ConfigFile.new(
          name: "/etc/iscsi/iscsid.conf",
          package_name: "open-iscsi",
          package_version: "2.0.873",
          changes: ["size", "mode", "md5", "user", "group", "time"],
          user: "nobody",
          group: "nobody",
          mode: "4700"
        )

        expected_apache_config_file_data = [
          apache_config_1, apache_config_2, apache_config_3, apache_config_4, apache_config_5
        ]
        @expected_data = ConfigFilesScope.new(
          extracted: false,
          files: ConfigFileList.new(
            [
              apache_config_1, apache_config_2, iscsi_config_1, apache_config_3,
              apache_config_4, apache_config_5
            ]
          )
        )

        allow_any_instance_of(ConfigFilesInspector).to receive(
          :packages_with_config_files
        ).and_return(["apache2-2.4.6", "open-iscsi-2.0.873"])
        allow_any_instance_of(ConfigFilesInspector).to receive(:config_file_changes).with(
          "apache2-2.4.6"
        ).and_return(expected_apache_config_file_data)
        allow_any_instance_of(ConfigFilesInspector).to receive(:config_file_changes).with(
          "open-iscsi-2.0.873"
        ).and_return(iscsi_config_1)
        allow_any_instance_of(ConfigFilesInspector).to receive(:check_requirements)
        stub_stat_commands(system, config_paths, stat_output)
      end

      context "with filters" do
        it "filters out the matching elements" do
          stub_stat_commands(system, config_paths - ["/usr/share/man/man1/time.1.gz"], stat_output)

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

          expect(description["config_files"]).to eq(@expected_data)
          expect(inspector.summary).to include("6 changed configuration files")
        end

        it "returns empty when no modified config files are there" do
          allow_any_instance_of(ConfigFilesInspector).to receive(
            :packages_with_config_files
          ).and_return([])

          inspector.inspect(filter)
          expected = ConfigFilesScope.new(
            extracted: false,
            files: ConfigFileList.new
          )
          expect(description["config_files"]).to eq(expected)
        end

        it "raises an error when requirements are not fulfilled" do
          allow_any_instance_of(ConfigFilesInspector).to receive(
            :check_requirements
          ).and_raise(Machinery::Errors::MissingRequirement)

          expect { inspector.inspect(filter) }.to raise_error(
            Machinery::Errors::MissingRequirement
          )
        end

        it "extracts changed configuration files" do
          config_file_directory = File.join(store.description_path(name), "config_files")
          expect(system).to receive(:retrieve_files).with(
            config_paths,
            config_file_directory
          )
          inspector.inspect(filter, extract_changed_config_files: true)

          expect(inspector.summary).to include("Extracted 6 changed configuration files")
          config_file_directory = File.join(store.description_path(name), "config_files")
          expect(File.stat(config_file_directory).mode & 0777).to eq(0700)
        end

        it "keep permissions on extracted config files dir" do
          config_file_directory = File.join(store.description_path(name), "config_files")
          expect(system).to receive(:retrieve_files).with(
            config_paths,
            config_file_directory
          )
          FileUtils.mkdir_p(config_file_directory)
          File.chmod(0750, config_file_directory)
          File.chmod(0750, store.description_path(name))

          inspector.inspect(filter, extract_changed_config_files: true)
          expect(inspector.summary).to include("Extracted 6 changed configuration files")
          expect(File.stat(config_file_directory).mode & 0777).to eq(0750)
        end

        it "removes config files on inspect without extraction" do
          config_file_directory = File.join(store.description_path(name), "config_files")
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
            config_paths,
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
            config_paths,
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
