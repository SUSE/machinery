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
      expect { @machinery.run_command(
        "#{machinery_command} invalid_command",
        as: "vagrant",
        stdout: :capture
      ) }.to raise_error(Pennyworth::ExecutionFailed)
    end

    it "processes help option" do
      output = @machinery.run_command(
        "#{machinery_command} -h",
        as: "vagrant",
        stdout: :capture
      )
      expect(output).to include("COMMANDS")
      expect(output).to include("help")
      expect(output).to include("GLOBAL OPTIONS")
    end

    it "processes help option for subcommands" do
      output = @machinery.run_command(
        "#{machinery_command} inspect --help",
        as: "vagrant",
        stdout: :capture
      )
      expect(output).to include("machinery [global options] inspect [command options] HOSTNAME")
    end

    it "does not offer --no-help or unneccessary negatable options" do
      global_output = @machinery.run_command(
        "#{machinery_command} --help",
        as: "vagrant",
        stdout: :capture
      )
      inspect_help_output = @machinery.run_command(
        "#{machinery_command} inspect --help",
        as: "vagrant",
        stdout: :capture
      )
      show_help_output = @machinery.run_command(
        "#{machinery_command} inspect --help",
        as: "vagrant",
        stdout: :capture
      )
      expect(global_output).to_not include("--[no-]help")
      expect(inspect_help_output).to_not include("--[no-]")
      expect(show_help_output).to_not include("--[no-]no-pager")
    end

    describe "inspect" do
      it "fails inspect for non existing scope" do
        expect { @machinery.run_command(
          "sudo #{machinery_command} inspect localhost --scope=foobar --name=test",
          as: "vagrant",
          stdout: :capture
        ) }.to raise_error(Pennyworth::ExecutionFailed, /The following scope is not supported: foobar/)
      end
    end

    describe "build" do
      it "fails without an output path" do
        expect { @machinery.run_command(
          "#{machinery_command} build test",
          as: "vagrant",
          stdout: :capture
        ) }.to raise_error(Pennyworth::ExecutionFailed, /image-dir is required/)
      end

      it "fails without a name" do
        expect { @machinery.run_command(
          "#{machinery_command} build --image-dir=/tmp/",
          as: "vagrant",
          stdout: :capture
        ) }.to raise_error(Pennyworth::ExecutionFailed, /You need to provide the required argument/)
      end
    end

    describe "list" do
      context "when more arguments than expected" do
        it "fails with a message" do
          message = /Too many arguments: got 2 arguments, expected none/
          expect {
            @machinery.run_command(
              "#{machinery_command} list foo bar",
              as: "vagrant",
              stderr: :capture
            )
          }.to raise_error(Pennyworth::ExecutionFailed, message)
        end
      end
    end
  end
end
