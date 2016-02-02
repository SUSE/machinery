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

describe ChangedManagedFilesRenderer do
  let(:system_description) {
    create_test_description(json: <<-EOF)
    {
      "changed_managed_files": {
        "_attributes": {
          "extracted": false
        },
        "_elements": [
          {
            "name": "/deleted/file",
            "package_name": "glibc",
            "package_version": "2.11.3",
            "status": "changed",
            "changes": [
              "deleted"
            ]
          },
          {
            "name": "/changed/file",
            "package_name": "login",
            "package_version": "3.41",
            "status": "changed",
            "changes": [
              "md5",
              "mode"
            ],
            "mode": "644",
            "user": "root",
            "group": "root",
            "md5_hash": "a571ffd6f0f9ab955f274d72c767d06b"
          },
          {
            "name": "/usr/sbin/vlock-main",
            "package_name": "vlock",
            "package_version": "2.2.3",
            "status": "error",
            "error_message": "cannot verify root:root 0755 - not listed in /etc/permissions"
          }
        ]
      }
    }
    EOF
  }

  describe "#render" do
    before(:each) do
      @output = ChangedManagedFilesRenderer.new.render(system_description)
    end

    it "prints a list of managed files" do
      expect(@output).to match(/\/deleted\/file.*deleted/)
      expect(@output).to match(/\/changed\/file.*md5, mode/)
    end

    it "shows the extraction status" do
      expect(@output).to include("Files extracted: no")
    end

    it "prints errored files as a separate list" do
      expect(@output).to match(/Errors:\n.*\/usr\/sbin\/vlock-main/)
    end

    context "when there are no changed managed files" do
      let(:system_description) { create_test_description(scopes: ["empty_changed_managed_files"]) }

      it "shows a message" do
        expect(@output).not_to match(/Files extracted: (yes|no)/)
        expect(@output).to include("There are no changed managed files.")
      end
    end
  end
end
