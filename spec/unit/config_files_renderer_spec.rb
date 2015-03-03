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

describe ConfigFilesRenderer do
  initialize_system_description_factory_store

  let(:system_description) {
    create_test_description(json: <<-EOF, store_on_disk: true)
    {
      "config_files": {
        "extracted": true,
        "files": [
          {
            "name": "/etc/default/grub",
            "package_name": "grub2",
            "package_version": "2.00",
            "status": "changed",
            "changes": [
              "mode"
            ],
            "user": "root",
            "group": "root",
            "mode": "600",
            "md5_hash": "93c6ef32d541b0c7c1f9f1eb40c3e6ae"
          },
          {
            "name": "/etc/postfix/main.cf",
            "package_name": "postfix",
            "package_version": "2.9.6",
            "changes": [
              "md5"
            ],
            "user": "root",
            "group": "root",
            "mode": "644",
            "md5_hash": "7b937326e997ce6b79b1bcd4431fc57a"
          },
          {
            "name": "/etc/my.cnf",
            "package_name": "mariadb",
            "package_version": "5.5.33",
            "status": "changed",
            "changes": [
              "size",
              "mode",
              "md5",
              "device_number",
              "link_path",
              "user",
              "group",
              "time",
              "capabilities"
            ],
            "user": "root",
            "group": "root",
            "mode": "600",
            "md5_hash": "b738b8a889b08ce1203901712bf653a9"
          }
        ]
      }
    }
    EOF
  }
  subject { ConfigFilesRenderer.new }

  describe "#render" do
    it "prints a list of config files" do
      output = subject.render(system_description)

      expect(output).to include("/etc/default/grub")
      expect(output).to include("mode")
      expect(output).to include("/etc/postfix/main.cf")
      expect(output).to include("md5")
    end

    it "shows the extraction status" do
      output = subject.render(system_description)

      expect(output).to include("Files extracted: yes")
    end

    context "with the --show-diff option" do
      context "when the diffs were not generated yet" do
        it "does not try to show a diff when the diffs were not generated yet" do
          expect {
            subject.render(system_description, show_diffs: true)
          }.to raise_error(Machinery::Errors::SystemDescriptionError)
        end
      end

      context "when the diffs were generated" do
        before(:each) do
          @diffs_dir = File.join(system_description.description_path, "analyze/config_file_diffs")
          FileUtils.mkdir_p(File.join(@diffs_dir, "/etc/postfix"))
          File.write(File.join(@diffs_dir, "/etc/postfix/main.cf.diff"), "main.cf.diff")
          File.write(File.join(@diffs_dir, "/etc/my.cnf.diff"), "my.cf.diff")
        end

        it "shows the diffs if the '--show-diff' option is set" do
          output = subject.render(system_description, show_diffs: true)

          expect(output).to include("Diff:\n    main.cf.diff\n")
        end

        it "shows a message when a diff file was not found" do
          File.delete File.join(@diffs_dir, "/etc/postfix/main.cf.diff")
          expect(Machinery::Ui).to receive(:warn) do |s|
            s.include?("Diff for /etc/postfix/main.cf was not found")
          end

          subject.render(system_description, show_diffs: true)
        end

        it "does not try to show a diff when the md5 did not change" do
          system_description["config_files"].each do |config_file|
            config_file.changes = ["deleted"]
          end
          subject.render(system_description, show_diffs: true)
          expect(subject).to_not receive(:render_diff_file)
        end

        it "shows the package-name and version" do
          output = subject.render(system_description)

          expect(output).to include("/etc/default/grub (grub2-2.00, mode)")
          expect(output).to include("/etc/postfix/main.cf (postfix-2.9.6, md5)")
        end

        it "shows all known rpm changes" do
          output = subject.render(system_description)

          expect(output).to include("/etc/my.cnf (mariadb-5.5.33, size, mode, md5, "\
            "device_number, link_path, user, group, time, capabilities)")
        end
      end
    end
  end
end
