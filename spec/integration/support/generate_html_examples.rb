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

shared_examples "generate html" do
  describe "generate-html" do
    it "creates an HTML export" do
      @machinery.inject_directory(
        File.join(Machinery::ROOT, "spec/data/descriptions/jeos/"),
        "/home/vagrant/.machinery/",
        owner: "vagrant",
        group: "users"
      )

      @machinery.run_command(
        "machinery generate-html jeos",
        as: "vagrant"
      )

      file_list = @machinery.run_command(
        "ls /home/vagrant/.machinery/jeos/index.html",
        stdout: :capture,
        as: "vagrant"
      ).chomp

      expect(file_list).to eq("/home/vagrant/.machinery/jeos/index.html")
    end
  end
end
