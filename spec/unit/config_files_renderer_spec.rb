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

describe ConfigFilesRenderer do
  let(:system_description) {
    create_test_description(json: <<-EOF)
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
          }
        ]
      }
    }
    EOF
  }
  subject { ConfigFilesRenderer.new }

  describe "#render" do
    include FakeFS::SpecHelpers

    it "prints a list of config files" do
      output = subject.render(system_description)

      expect(output).to include("/etc/default/grub")
      expect(output).to include("mode")
      expect(output).to include("/etc/postfix/main.cf")
      expect(output).to include("md5")
    end

    describe "with the --show-diff option" do
      include FakeFS::SpecHelpers

      before(:each) do
        allow(SystemDescriptionStore).to receive(:new).
          and_return(double(file_store: "/tmp"))
      end

      it "shows the diffs if the '--show-diff' option is set" do
        FileUtils.mkdir_p("/tmp/etc/postfix")
        File.write("/tmp/etc/postfix/main.cf.diff", "main.cf.diff")

        output = subject.render(system_description, show_diffs: true)

        expect(output).to include("Diff:\n    main.cf.diff\n")
      end

      it "shows a message when a diff file was not found" do
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

      it "does not try to show a diff when the diffs were not generated yet" do
        expect(SystemDescriptionStore).to receive(:new).
          and_return(double(file_store: nil))

        expect {
          subject.render(system_description, show_diffs: true)
        }.to raise_error(Machinery::Errors::SystemDescriptionError)
      end
    end
  end
end
