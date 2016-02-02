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

describe "Manifest" do
  initialize_system_description_factory_store

  describe "#load" do
    it "raises Errors::SystemDescriptionNotFound if the manifest file doesn't exist" do
      expect {
        Manifest.load("not_existing", "/does/not/exist")
      }.to raise_error(Machinery::Errors::SystemDescriptionNotFound)
    end

    it "raises in case of a missing comma" do
      path = File.join(Machinery::ROOT, "spec/data/schema/invalid_json/missing_comma.json")
      expected = <<EOF
The JSON data of the system description 'name' couldn't be parsed. \
The following error occured around line 13 in file '#{path}':

unexpected token at '{
        "name": "/boot/grub/e2fs_stage1_5",
        "type": "file",
        "user": "root"
        "group": "root",
        "size": 8608,
        "mode": "644"
      }
EOF
      expected.chomp!
      expect {
        Manifest.load("name", path)
      }.to raise_error(Machinery::Errors::SystemDescriptionError, expected)
    end

    it "raises in case of a missing opening bracket" do
      path = File.join(
        Machinery::ROOT,
        "spec/data/schema/invalid_json/missing_opening_bracket.json"
      )
      expected = <<EOF
The JSON data of the system description 'name' couldn't be parsed. The following error occured \
in file '#{path}':

An opening bracket, a comma or quotation is missing in one of the global scope definitions or \
in the meta section. Unlike issues with the elements of the scopes, our JSON parser isn't able \
to locate issues like these.
EOF
      expected.chomp!
      expect {
        Manifest.load("name", path)
      }.to raise_error(Machinery::Errors::SystemDescriptionError, expected)
    end
  end

  describe "#validate" do
    capture_machinery_output
    it "validates compatible descriptions" do
      manifest = Manifest.new("name", <<-EOT)
        {
          "meta": {
            "format_version": 2,
            "os": "invalid"
          }
        }
      EOT
      expect {
        manifest.validate!
      }.to raise_error(Machinery::Errors::SystemDescriptionError)
    end

    it "shows a warning when validating compatible descriptions" do
      manifest = Manifest.new("name", <<-EOT)
        {
          "meta": {
            "format_version": 2,
            "os": "invalid"
          }
        }
      EOT
      manifest.validate
      expected_output = <<-EOF.chomp
Warning: System Description validation errors:
The property '#/meta/os' of type String did not match the following type:
EOF
      expect(captured_machinery_output).to include(expected_output)
    end

    it "doesn't validate incompatible descriptions" do
      manifest = Manifest.new("name", <<-EOT)
        {
          "meta": {
            "os": "invalid"
          }
        }
      EOT
      expect {
        manifest.validate!
      }.not_to raise_error

      expect {
        manifest.validate
      }.not_to raise_error
    end

    it "does not try to validate descriptions with unknown format versions" do
      manifest = Manifest.new("name", <<-EOT)
        {
          "meta": {
            "format_version": 99999
          }
        }
      EOT
      expect {
        manifest.validate!
      }.not_to raise_error

      expect {
        manifest.validate
      }.not_to raise_error
    end
  end
end
