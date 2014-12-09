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

shared_examples "autoyast export" do
  let(:autoyast_export_dir) { "/tmp/autoyast-export" }

  describe "export-autoyast" do
    it "creates an autoyast profile" do
      @machinery.inject_directory(
        File.join(Machinery::ROOT, "spec/data/descriptions/jeos/"),
        "/home/vagrant/.machinery/",
        owner: "vagrant",
        group: "users"
      )

      measure("export to autoyast") do
        @machinery.run_command(
          "machinery export-autoyast jeos --autoyast-dir=#{autoyast_export_dir}",
          as: "vagrant"
        )
      end

      file_list = @machinery.run_command(
        "ls #{autoyast_export_dir}",
        stdout: :capture,
        as: "vagrant"
      ).split("\n")
      expect(file_list).to include("autoinst.xml")
    end

    it "generates a proper profile" do
      expected = File.read(File.join(Machinery::ROOT, "spec", "data", "autoyast", "jeos.xml"))
      actual = @machinery.run_command(
        "cat #{autoyast_export_dir}/autoinst.xml",
        stdout: :capture,
        as: "vagrant"
      )
      expect(actual).to eq(expected)
    end
  end
end
