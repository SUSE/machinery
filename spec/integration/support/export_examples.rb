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

shared_examples "export" do |base|
  after(:all) do
    @machinery.cleanup_directory("/tmp/#{base}-kiwi")
    @machinery.cleanup_directory("/tmp/#{base}-autoyast")
  end

  def read_kiwi_export_data(base, file)
    File.read(File.join("spec", "data", "export-kiwi", base, file))
  end

  describe "export-kiwi" do
    it "creates a kiwi description #{base}" do
      @machinery.inject_directory(
        File.join("spec/data/descriptions/jeos/", base),
        machinery_config[:machinery_dir],
        owner: machinery_config[:owner],
        group: machinery_config[:group]
      )

      measure("export to kiwi") do
        expect(
          @machinery.run_command(
            "#{machinery_command} export-kiwi #{base} --kiwi-dir=/tmp --force",
            as: machinery_config[:owner]
          )
        ).to succeed
      end

      expect(
        @machinery.run_command("ls /tmp/#{base}-kiwi", as: machinery_config[:owner])
      ).to succeed.and have_stdout("config.sh\nconfig.xml\nREADME.md\nroot\n")
    end

    it "generates a proper config.sh" do
      expected = read_kiwi_export_data(base, "config.sh")
      expect(
        @machinery.run_command("cat /tmp/#{base}-kiwi/config.sh", as: machinery_config[:owner])
      ).to succeed.and have_stdout(expected)
    end

    it "generates a proper config.xml" do
      expected = read_kiwi_export_data(base, "config.xml")
      expect(
        @machinery.run_command("cat /tmp/#{base}-kiwi/config.xml", as: machinery_config[:owner])
      ).to succeed.and have_stdout(expected)
    end

    it "generates a proper root tree" do
      expected = read_kiwi_export_data(base, "root")
      expect(
        @machinery.run_command("ls -1R --time-style=+ /tmp/#{base}-kiwi/root",
          as: machinery_config[:owner])
      ).to succeed.and have_stdout(expected)
    end
  end

  describe "export-autoyast #{base}" do
    it "creates an autoyast profile" do
      @machinery.inject_directory(
        File.join("spec/data/descriptions/jeos/", base),
        machinery_config[:machinery_dir],
        owner: machinery_config[:owner],
        group: machinery_config[:group]
      )

      measure("export to autoyast") do
        expect(
          @machinery.run_command(
            "#{machinery_command} export-autoyast #{base} --autoyast-dir=/tmp",
            as: machinery_config[:owner]
          )
        ).to succeed
      end

      expect(
        @machinery.run_command(
          "ls /tmp/#{base}-autoyast",
          as: machinery_config[:owner]
        )
      ).to succeed.and include_stdout("autoinst.xml")
    end
  end
end
