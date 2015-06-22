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

shared_examples "autoyast export" do
  after(:all) do
    @machinery.cleanup_directory("/tmp/jeos-autoyast")
  end

  describe "export-autoyast" do
    it "creates an autoyast profile" do
      @machinery.inject_directory(
        File.join(Machinery::ROOT, "spec/data/descriptions/jeos/"),
        machinery_config[:machinery_dir],
        owner: machinery_config[:owner],
        group: machinery_config[:group]
      )

      measure("export to autoyast") do
        expect(
          @machinery.run_command(
            "#{machinery_command} export-autoyast jeos --autoyast-dir=/tmp",
            as: machinery_config[:owner]
          )
        ).to succeed
      end

      expect(
        @machinery.run_command(
          "ls /tmp/jeos-autoyast",
          as: machinery_config[:owner]
        )
      ).to succeed.and include_stdout("autoinst.xml")
    end
  end
end
