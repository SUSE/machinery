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

describe SystemDescriptionValidator do
  describe "#validate_json" do
    it "validates against the system description format version 1" do
      expect_any_instance_of(JsonValidator).to receive(:global_schema).with(1).and_call_original
      expect_any_instance_of(JsonValidator).to_not receive(:global_schema).with(2)
      SystemDescriptionValidator.new(JSON.parse(<<-EOT), nil).validate_json
          {
            "meta": {
              "format_version": 1,
              "changed_managed_files": {
                "modified": "2014-08-12T09:12:54Z",
                "hostname": "host.example.com"
              }
            }
          }
      EOT
    end

    it "validates against the system description format version 2" do
      expect_any_instance_of(JsonValidator).to_not receive(:global_schema).with(1)
      expect_any_instance_of(JsonValidator).to receive(:global_schema).with(2).and_call_original
      SystemDescriptionValidator.new(JSON.parse(<<-EOT), nil).validate_json
        {
          "meta": {
            "format_version": 2,
            "changed_managed_files": {
              "modified": "2014-08-12T09:12:54Z",
              "hostname": "host.example.com"
            }
          }
        }
      EOT
    end

    it "validates the global and the scope schemas" do
      validator = SystemDescriptionValidator.new(JSON.parse(<<-EOT), nil)
        {
          "changed_managed_files": {
            "extracted": true,
            "files": [
              {
                "name": "/etc/crontab",
                "package_name": "cronie",
                "package_version": "1.4.8",
                "status": "changed",
                "changes": [
                  "invalid"
                ],
                "user": "root",
                "group": "root",
                "mode": "644"
              }
            ]
          },
          "meta": {
            "format_version": 2,
            "changed_managed_files": "invalid"
          }
        }
      EOT

      expected_global_error = /The property '#\/meta\/changed_managed_files' of type String did not match the following type: object/
      expected_scope_error = /In scope changed_managed_files: The property #0 \(files\/changes\) of type Hash did not match any of the required schemas\./

      errors = validator.validate_json
      expect(errors[0]).to match(expected_global_error)
      expect(errors[1]).to match(expected_scope_error)
    end
  end
end
