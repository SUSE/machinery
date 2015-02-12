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

describe JsonValidator do
  describe ".cleanup_json_error_message" do
    let (:validator)  { JsonValidator }
    describe "shows the correct position and reduces the clutter" do
      it "for missing attribute in unmanaged-files errors" do
        error = "The property '#/0/type/0/1/2/3/type/4/5' of type Array did not match any of the required schemas in schema 89d6911a-763e-51fd-8e35-257a1f31d377#"
        expected = "The property #5 of type Array did not match any of the required schemas."
        expect(validator.cleanup_json_error_message(error, "unmanaged_files")).
          to eq(expected)
      end

      it " for missing attribute in unmanaged_files and filters the type elements" do
        error = "The property '#/0/type/0/1/2/3/type/4/5/type/6/type/7/8/9/10/11/type/12/17/18/19/20/21/22/23/24/25/26/27/28/29/type/30/31/33/34/35/36/37/38/39/40/41/42/43/44/45/46/47/48/49/476/477/478/479/480/481/482/483/484/485/486/487/488/489/490/491/492/493/494/495/496/497/498/499/500/501/504/type/505/type/506/type/507/type/508/type/509/510/511/512/513/514/515/516/517/518/519/520/type/555' of type Array did not match any of the required schemas in schema 89d6911a-763e-51fd-8e35-257a1f31d377#"
        expected = "The property #555 of type Array did not match any of the required schemas."
        expect(validator.cleanup_json_error_message(error, "unmanaged_files")).
          to eq(expected)
      end

      it "for missing attribute in services" do
        error = "The property '#/services/2' did not contain a required property of 'state' in schema 73e30722-b9a4-573a-95a9-1f6882dd11a5#"
        expected = "The property #2 (services) did not contain a required property of 'state'."
        expect(validator.cleanup_json_error_message(error, "services")).
          to eq(expected)
      end

      it "for wrong status in services" do
        error = "The property '#/services/4/state' was not of a minimum string length of 1 in schema 73e30722-b9a4-573a-95a9-1f6882dd11a5#"
        expected = "The property #4 (services/state) was not of a minimum string length of 1."
        expect(validator.cleanup_json_error_message(error, "services")).
          to eq(expected)
      end

      it "for missing attribute in os" do
        error = "The property '#/' did not contain a required property of 'version' in schema 547e11fe-8e4b-574a-bec5-66ada4e5e2ec#"
        expected = "The property did not contain a required property of 'version'."
        expect(validator.cleanup_json_error_message(error, "os")).
          to eq(expected)
      end

      it "for wrong attribute type in users" do
        error = "The property '#/3/gid' of type String did not match one or more of the following types: integer, null in schema 769f5514-0330-592b-b538-87df746cb3d3#"
        expected = "The property #3 (gid) of type String did not match one or more of the following types: integer, null."
        expect(validator.cleanup_json_error_message(error, "users")).
          to eq(expected)
      end

      it "for unknown repository type and mentions the affected attribute 'type'" do
        error = "The property '#/4/type' value 0 did not match one of the following values: yast2, rpm-md, plaindir, null in schema 5ee44188-86f1-5823-92ac-e1068304cbf2#"
        expected = "The property #4 (type) value 0 did not match one of the following values: yast2, rpm-md, plaindir, null."
        expect(validator.cleanup_json_error_message(error, "repositories")).
          to eq(expected)
      end

      it "for unknown status in config-files" do
        error = "The property '#/0/1/status' of type Hash did not match any of the required schemas in schema 5257ca96-7f5c-5c72-b44e-80abca5b0f38#"
        expected = "The property #1 (status) of type Hash did not match any of the required schemas."
        expect(validator.cleanup_json_error_message(error, "config_files")).
          to eq(expected)
      end
    end
  end
end
