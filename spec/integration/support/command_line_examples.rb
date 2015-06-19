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

shared_examples "CLI" do
  describe "CLI" do
    it "throws an error on invalid command" do
      expect(
        @machinery.run("#{machinery_command} invalid_command", as: "vagrant")
      ).to fail.with_exit_code(1).and include_stderr("Unknown command 'invalid_command'")
    end

    it "processes help option" do
      expect(
        @machinery.run("#{machinery_command} -h", as: "vagrant")
      ).to succeed.and have_stdout(/GLOBAL OPTIONS.*COMMANDS.*help/m)
    end

    it "processes help option for subcommands" do
      expect(
        @machinery.run("#{machinery_command} inspect --help", as: "vagrant")
      ).to succeed.and include_stdout("machinery [global options] inspect [command options] HOSTNAME")
    end

    it "does not offer --no-help or unneccessary negatable options" do
      expect(
        @machinery.run("#{machinery_command} --help", as: "vagrant")
      ).to succeed.and not_include_stdout("--[no-]help")

      expect(
        @machinery.run("#{machinery_command} inspect --help", as: "vagrant")
      ).to succeed.and not_include_stdout("--[no-]")

      expect(
        @machinery.run("#{machinery_command} show --help", as: "vagrant")
      ).to succeed.and not_include_stdout("--[no-]no-pager")
    end

    describe "inspect" do
      it "fails inspect for non existing scope" do
        expect(
          @machinery.run(
            "sudo #{machinery_command} inspect localhost --scope=foobar --name=test",
            as: "vagrant"
          )
        ).to fail.and include_stderr("The following scope is not supported: foobar")
      end
    end

    describe "build" do
      it "fails without an output path" do
        expect(
          @machinery.run("#{machinery_command} build test", as: "vagrant")
        ).to fail.and include_stderr("image-dir is required")
      end

      it "fails without a name" do
        expect(
          @machinery.run("#{machinery_command} build --image-dir=/tmp/", as: "vagrant")
        ).to fail.and include_stderr("You need to provide the required argument")
      end
    end

    describe "validate number of given arguments" do
      context "when no arguments are expected" do
        it "fails with a message" do
          expect(
            @machinery.run("#{machinery_command} list foo bar", as: "vagrant")
          ).to fail.and include_stderr("Too many arguments: got 2 arguments, expected none")
        end
      end

      context "when a specific number of arguments are expected" do
        it "fails with a message" do
          expect(
            @machinery.run("#{machinery_command} show foo bar", as: "vagrant")
          ).to fail.and include_stderr("Too many arguments: got 2 arguments, expected only: NAME")
        end
      end

      context "when multiple (undefined) number of arguments are expected" do
        it "fails with a message" do
          expect(
            @machinery.run("#{machinery_command} remove", as: "vagrant")
          ).to fail.and include_stderr("No arguments given. Nothing to do.")
        end
      end
    end
  end
end
