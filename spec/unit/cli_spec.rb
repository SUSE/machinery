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

require_relative "spec_helper"

describe Cli do
  describe "#initialize" do
    before :each do
      allow_any_instance_of(IO).to receive(:puts)
    end

    it "sets the log level to :info by default" do
      run_command(["show"])

      expect(Machinery.logger.level).to eq(Logger::INFO)
    end

    it "sets the log level to :debug when the --debug option is given" do
      run_command(["--debug", "show"])

      expect(Machinery.logger.level).to eq(Logger::DEBUG)
    end
  end

  context "machinery test directory" do
    include_context "machinery test directory"

    let(:example_host) { "myhost" }
    let(:description) { SystemDescription.new("foo") }

    before(:each) do
      allow_any_instance_of(SystemDescriptionStore).to receive(:default_path).
        and_return(test_base_path)
      create_machinery_dir
    end

    describe "#inspect" do
      include_context "machinery test directory"

      before :each do
        allow_any_instance_of(InspectTask).to receive(:inspect_system).
          and_return(description)
        allow(SystemDescription).to receive(:delete)
      end

      it "uses the provided host name if specified at the end" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            example_host,
            example_host,
            an_instance_of(CurrentUser),
            Inspector.all_scopes,
            {}
          ).
          and_return(description)

        run_command(["inspect", example_host])
      end

      it "uses the provided name if specified with --name" do
        name = "test"
        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            example_host,
            name,
            an_instance_of(CurrentUser),
            Inspector.all_scopes,
            {}
           ).
           and_return(description)

        run_command(["inspect", "--name=#{name}", example_host])
      end

      it "uses the host name if no --name is provided" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            example_host,
            example_host,
            an_instance_of(CurrentUser),
            Inspector.all_scopes,
            {}
           ).
          and_return(description)

        run_command(["inspect", example_host])
      end

      it "only inspects the scopes provided (separated by ',')" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            example_host,
            example_host,
            an_instance_of(CurrentUser),
            ["packages", "repositories"],
            {}
          ).
          and_return(description)

        run_command(["inspect", "--scope=packages,repositories", example_host])
      end

      it "only inspects the scopes provided (separated by ' ')" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            example_host,
            example_host,
            an_instance_of(CurrentUser),
            ["packages", "repositories"],
            {}
          ).
          and_return(description)

        run_command(["inspect", "--scope=packages repositories", example_host])
      end

      it "inspects all scopes if no --scope is provided" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            example_host,
            example_host,
            an_instance_of(CurrentUser),
            Inspector.all_scopes,
            {}
          ).
          and_return(description)

        run_command(["inspect", example_host])
      end

      it "doesn't inspect the excluded scopes" do
        scope_list = Inspector.all_scopes
        scope_list.delete("packages")
        scope_list.delete("repositories")

        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            example_host,
            example_host,
            an_instance_of(CurrentUser),
            scope_list,
            {}
          ).
          and_return(description)

        run_command(["inspect", "--exclude-scope=packages repositories", example_host])
      end

      describe "file extraction" do
        it "doesn't extract files when --extract-files is not specified" do
          expect_any_instance_of(InspectTask).to receive(:inspect_system).
            with(
              an_instance_of(SystemDescriptionStore),
              example_host,
              example_host,
              an_instance_of(CurrentUser),
              Inspector.all_scopes,
              {}
            ).
            and_return(description)

          run_command(["inspect", example_host])
        end

        it "extracts changed config/managed files and umanaged files when --extract-files is specified" do
          expect_any_instance_of(InspectTask).to receive(:inspect_system).
            with(
              an_instance_of(SystemDescriptionStore),
              example_host,
              example_host,
              an_instance_of(CurrentUser),
              Inspector.all_scopes,
              :extract_changed_config_files=>true, :extract_unmanaged_files=>true, :extract_changed_managed_files=>true
            ).
            and_return(description)

          run_command(["inspect", "--extract-files", example_host])
        end

        it "extracts only changed config files files when --extract-changed-config-files is specified" do
          expect_any_instance_of(InspectTask).to receive(:inspect_system).
            with(
              an_instance_of(SystemDescriptionStore),
              example_host,
              example_host,
              an_instance_of(CurrentUser),
              Inspector.all_scopes,
              :extract_changed_config_files=>true
            ).
            and_return(description)

          run_command(["inspect", "--extract-changed-config-files", example_host])
        end

        it "extracts only umanaged files when --extract-unmanaged-files is specified" do
          expect_any_instance_of(InspectTask).to receive(:inspect_system).
            with(
              an_instance_of(SystemDescriptionStore),
              example_host,
              example_host,
              an_instance_of(CurrentUser),
              Inspector.all_scopes,
              :extract_unmanaged_files=>true
            ).
            and_return(description)

          run_command(["inspect", "--extract-unmanaged-files", example_host])
        end
      end
    end

    describe "#build" do
      it "triggers a build" do
        path = "/tmp/output_path"
        description = SystemDescription.from_json("name", test_manifest)
        description.name = "descriptionx"

        expect_any_instance_of(BuildTask).to receive(:build).
          with(description, path, {:enable_dhcp=>false, :enable_ssh=>false})

        run_command(["build", "description1", "--image-dir=#{path}"])
      end
    end

    describe "#show" do
      it "triggers the show task for packages when scope packages is specified" do
        description = SystemDescription.from_json("name", test_manifest)
        expect_any_instance_of(ShowTask).to receive(:show).with(
          description, ["packages"], :no_pager => true, :show_diffs => false)

        run_command(["show", "description1", "--scope=packages", "--no-pager"])
      end
    end

    describe "#export_kiwi" do
      it "triggers a KIWI export" do
        description = SystemDescription.from_json("name", test_manifest)
        expect_any_instance_of(KiwiExportTask).to receive(:export).
          with(description, "/tmp/export", force: false)

        run_command(["export-kiwi", "description1", "--kiwi-dir=/tmp/export"])
      end

      it "forwards the force option" do
        description = SystemDescription.from_json("name", test_manifest)
        expect_any_instance_of(KiwiExportTask).to receive(:export).
          with(description, "/tmp/export", force: true)

        run_command(["export-kiwi", "description1", "--kiwi-dir=/tmp/export", "--force"])
      end
    end

    describe "#analyze" do
      it "fails when an unsupported operation is called" do
        SystemDescription.from_json("name", test_manifest)

        expect(STDERR).to receive(:puts).with(/.*The operation 'foo' is not supported.*/)
        run_command(["analyze", "description1", "--operation=foo"])
      end

      it "triggers the analyze task" do
        description = SystemDescription.from_json("name", test_manifest)
        expect_any_instance_of(AnalyzeConfigFileDiffsTask).to receive(:analyze).with(
          description
        )

        run_command(["analyze", "description1", "--operation=config-file-diffs"])
      end
    end
  end

  describe "#remove" do
    it "triggers the remove task" do
      expect_any_instance_of(RemoveTask).to receive(:remove).
        with(an_instance_of(SystemDescriptionStore), "foo", anything())

      run_command(["remove", "foo"])
    end
  end

  describe "#list" do
    it "triggers the list task" do
      expect_any_instance_of(ListTask).to receive(:list).
          with(an_instance_of(SystemDescriptionStore), anything())
      run_command(["list"])
    end
  end

  describe "#copy" do
    it "triggers the copy task" do
      expect_any_instance_of(CopyTask).to receive(:copy).
        with(an_instance_of(SystemDescriptionStore), "foo", "bar")
      run_command(["copy", "foo", "bar"])
    end
  end

  describe "#process_scope_option" do
    it "returns the scopes which are provided" do
      expect(Cli.process_scope_option("test1,test2", nil)).to eq(["test1", "test2"])
      expect(Cli.process_scope_option("test1 test2", nil)).to eq(["test1", "test2"])
    end

    it "returns all scopes if no scopes are provided" do
      expect(Cli.process_scope_option(nil,nil)).to eq(Inspector.all_scopes)
    end

    it "returns all scopes except the excluded scope" do
      scope_list = Inspector.all_scopes
      scope_list.delete("os")
      expect(Cli.process_scope_option(nil, "os")).to eq(scope_list)
    end

    it "raises an error if both scopes and excluded scopes are given" do
      expect { Cli.process_scope_option("scope1", "scope2") }.to  raise_error(Machinery::Errors::InvalidCommandLine)
    end
  end

  describe "#error_handling" do
    it "shows stderr, stdout and the backtrace for unexpected errors" do
      expected_cheetah_out = <<-EOT
Cheetah::ExecutionFailed

Error output:
This is STDERR
Standard output:
This is STDOUT

Backtrace:
      EOT

      expect(STDERR).to receive(:puts).with(/Machinery experienced an unexpected error. Please file a bug report at https:\/\/github.com\/SUSE\/machinery\/issues\/new.\n/)
      expect(STDERR).to receive(:puts).with(/#{expected_cheetah_out}/)
      begin
        # Actually raise the exception, so we have a backtrace
        raise(Cheetah::ExecutionFailed.new(nil, nil, "This is STDOUT", "This is STDERR"))
      rescue => e
        expect{ Cli.handle_error(e) }.to raise_error(SystemExit)
      end
    end
  end

  describe ".internal_to_cli_scope_names" do
    it "converts the internal names to the cli ones ('_' to '-') and returns an array" do
      expect(Cli.internal_to_cli_scope_names("foo_bar")).to eq(["foo-bar"])
    end

    it "accepts arrays" do
      expect(Cli.internal_to_cli_scope_names(["foo_bar", "bar_baz"])).
        to match_array(["foo-bar", "bar-baz"])
    end
  end

  describe ".cli_to_internal_scope_names" do
    it "converts the cli names to the internal ones ('-' to '_') and returns an array" do
      expect(Cli.cli_to_internal_scope_names("foo-bar")).to eq(["foo_bar"])
    end

    it "accepts arrays" do
      expect(Cli.cli_to_internal_scope_names(["foo-bar", "bar-baz"])).
        to match_array(["foo_bar", "bar_baz"])
    end
  end

  private

  def run_command(*args)
    Cli.run(*args)
  rescue SystemExit
  end
end
