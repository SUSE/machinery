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
        @machinery.run_command("#{machinery_command} invalid_command", as: "vagrant")
      ).to fail.with_exit_code(1).and include_stderr("Unknown command 'invalid_command'")
    end

    it "throws an error on ambiguous option" do
      expect(
        @machinery.run_command("#{machinery_command} inspect --extract localhost", as: "vagrant")
      ).to fail.with_exit_code(1).and include_stderr(
        "ambiguous option: --extract", "Run #{0} inspect --help for more information."
        )
    end

    it "processes help option" do
      expect(
        @machinery.run_command("#{machinery_command} -h", as: "vagrant")
      ).to succeed.and have_stdout(/GLOBAL OPTIONS.*COMMANDS.*help/m)
    end

    it "processes help option for subcommands" do
      expect(
        @machinery.run_command("#{machinery_command} inspect --help", as: "vagrant")
      ).to succeed.and include_stdout(
        "machinery [global options] inspect [command options] HOSTNAME"
      )
    end

    it "does not offer --no-help or unneccessary negatable options" do
      expect(
        @machinery.run_command("#{machinery_command} --help", as: "vagrant")
      ).to succeed.and not_include_stdout("--[no-]help")

      expect(
        @machinery.run_command("#{machinery_command} inspect --help", as: "vagrant")
      ).to succeed.and not_include_stdout("--[no-]")

      expect(
        @machinery.run_command("#{machinery_command} show --help", as: "vagrant")
      ).to succeed.and not_include_stdout("--[no-]no-pager")
    end

    describe "inspect" do
      it "fails inspect for non existing scope" do
        expect(
          @machinery.run_command(
            "sudo #{machinery_command} inspect localhost --scope=foobar --name=test",
            as: "vagrant"
          )
        ).to fail.and include_stderr("The following scope is not supported: foobar")
      end
    end

    describe "build" do
      it "fails without an output path" do
        expect(
          @machinery.run_command("#{machinery_command} build test", as: "vagrant")
        ).to fail.and include_stderr("image-dir is required")
      end

      it "fails without a name" do
        expect(
          @machinery.run_command("#{machinery_command} build --image-dir=/tmp/", as: "vagrant")
        ).to fail.and include_stderr("You need to provide the required argument")
      end
    end

    describe "config" do
      context "--help" do
        it "shows the alternative synopsis" do
          expect(
            @machinery.run_command("#{machinery_command} config --help", as: "vagrant")
          ).to succeed.and include_stdout(
            "machinery [global options] config [KEY][=VALUE]"
          )
        end
      end
    end

    describe "compare" do
      before(:each) do
        @machinery.run_command("#{machinery_command} config experimental_features true", \
          as: "vagrant")
      end

      it "checks if a port gets validated" do
        expect(@machinery.run_command("#{machinery_command} compare description1 description2 " \
          "--port=1 --html", as: "vagrant")).to fail.and include_stderr(
            "Please choose a port between 2 and 65535."
          )
      end
    end

    describe "show" do
      it "checks if a port gets validated" do
        expect(@machinery.run_command("#{machinery_command} show description1 " \
          "--port=1 --html", as: "vagrant")).to fail.and include_stderr(
            "Please choose a port between 2 and 65535."
          )
      end
    end

    describe "serve" do
      it "checks if a port gets validated" do
        expect(@machinery.run_command("#{machinery_command} serve description1 --port=1", \
          as: "vagrant")).to fail.and include_stderr("Please choose a port between 2 and 65535.")
      end
    end

    describe "validate number of given arguments" do
      context "when no arguments are expected" do
        it "fails with a message" do
          expect(
            @machinery.run_command("#{machinery_command} man list", as: "vagrant")
          ).to fail.and include_stderr("Too many arguments: got 1 argument, expected none")
        end
      end

      context "when a specific number of arguments are expected" do
        it "fails with a message" do
          expect(
            @machinery.run_command("#{machinery_command} show foo bar", as: "vagrant")
          ).to fail.and include_stderr("Too many arguments: got 2 arguments, expected only: NAME")
        end
      end

      context "when multiple (undefined) number of arguments are expected" do
        it "fails" do
          expect(
            @machinery.run_command("#{machinery_command} remove", as: "vagrant")
          ).to fail
        end
      end

      context "when a switch invalidates number of arguments needed" do
        it "succeeds without failure" do
          expect(
            @machinery.run_command("#{machinery_command} remove --all", as: "vagrant")
          ).to succeed
          expect(
            @machinery.run_command("#{machinery_command} remove --verbose --all", as: "vagrant")
          ).to succeed
        end
      end
    end
  end
end
