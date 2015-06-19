#  Copyright (c) 2013-2015 SUSE LLC
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 3 of the GNU General Public License as
#  published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.
#
#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

shared_examples "validate" do
  describe "validate" do
    it "validates a system description against JSON schemas" do
      expected = <<EOF
In scope repositories: The property #0 did not contain a required property of 'url'.
In scope services: The property #4 (services/state) was not of a minimum string length of 1.
EOF
      system_description_file = "spec/data/descriptions/validation-error/manifest.json"
      system_description_dir = File.dirname(system_description_file)

      @machinery.inject_directory(
        system_description_dir,
        "/home/vagrant/.machinery/",
        owner: "vagrant",
        group: "users"
      )

      expect(
        @machinery.run("machinery validate validation-error", as: "vagrant")
      ).to fail.and have_stderr(/#{Regexp.quote(expected)}/)
    end

    it "checks a system description for valid JSON syntax" do
      expected = <<EOF
The JSON data of the system description 'invalid-json' couldn't be parsed. The following error occured in file '/home/vagrant/.machinery/invalid-json/manifest.json':

An opening bracket, a comma or quotation is missing in one of the global scope definitions or in the meta section. Unlike issues with the elements of the scopes, our JSON parser isn't able to locate issues like these.
EOF
      system_description_file = "spec/data/descriptions/invalid-json/manifest.json"
      system_description_dir = File.dirname(system_description_file)

      @machinery.inject_directory(
        system_description_dir,
        "/home/vagrant/.machinery/",
        owner: "vagrant",
        group: "users"
      )

      expect(
        @machinery.run("machinery validate invalid-json", as: "vagrant")
      ).to fail.and have_stderr(/#{Regexp.quote(expected)}/)
    end
  end
end
