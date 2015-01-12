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

require_relative "spec_helper"

describe Cli do
  silence_machinery_output

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
    let(:description) {
      SystemDescription.new("foo", SystemDescriptionMemoryStore.new)
    }

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

      it "only inspects the scopes provided" do
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

      it "only inspects a scope once even if it was provided multiple times" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            example_host,
            example_host,
            an_instance_of(CurrentUser),
            ["packages"],
            {}
          ).
          and_return(description)

        run_command(["inspect", "--scope=packages,packages", example_host])
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

        run_command(["inspect", "--exclude-scope=packages,repositories", example_host])
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
        description = create_test_description(json: test_manifest)
        description.name = "descriptionx"

        expect_any_instance_of(BuildTask).to receive(:build).
          with(description, path, {:enable_dhcp=>false, :enable_ssh=>false})

        run_command(["build", "description1", "--image-dir=#{path}"])
      end
    end

    describe "#show" do
      it "triggers the show task for packages when scope packages is specified" do
        description = create_test_description(json: test_manifest)
        expect_any_instance_of(ShowTask).to receive(:show).with(
          description, ["packages"], :no_pager => true, :show_diffs => false, :show_html => false)

        run_command(["show", "description1", "--scope=packages", "--no-pager"])
      end
    end

    describe "#validate" do
      it "triggers a validation" do
        name = "description1"
        expect_any_instance_of(ValidateTask).to receive(:validate).with(
          an_instance_of(SystemDescriptionStore), name)

        run_command(["validate", "description1"])
      end
    end

    describe "#export_kiwi" do
      before(:each) do
        @kiwi_config = double
        allow(KiwiConfig).to receive(:new).and_return(@kiwi_config)
      end

      it "triggers a KIWI export" do
        expect_any_instance_of(ExportTask).to receive(:export).
          with("/tmp/export", force: false)

        run_command(["export-kiwi", "description1", "--kiwi-dir=/tmp/export"])
      end

      it "forwards the force option" do
        expect_any_instance_of(ExportTask).to receive(:export).
          with("/tmp/export", force: true)

        run_command(["export-kiwi", "description1", "--kiwi-dir=/tmp/export", "--force"])
      end
    end

    describe "#export_autoyast" do
      before(:each) do
        @autoyast = double
        allow(Autoyast).to receive(:new).with(instance_of(SystemDescription)).
          and_return(@autoyast)
      end

      it "triggers a AutoYaST export" do
        expect_any_instance_of(ExportTask).to receive(:export).
          with("/tmp/export", force: false)

        run_command(["export-autoyast", "description1", "--autoyast-dir=/tmp/export"])
      end

      it "forwards the force option" do
        expect_any_instance_of(ExportTask).to receive(:export).
          with("/tmp/export", force: true)

        run_command(["export-autoyast", "description1", "--autoyast-dir=/tmp/export", "--force"])
      end
    end

    describe "#analyze" do
      it "fails when an unsupported operation is called" do
        create_test_description(json: test_manifest)

        expect(Machinery::Ui).to receive(:error).with(/.*The operation 'foo' is not supported.*/)
        run_command(["analyze", "description1", "--operation=foo"])
      end

      it "triggers the analyze task" do
        description = create_test_description(json: test_manifest)
        expect_any_instance_of(AnalyzeConfigFileDiffsTask).to receive(:analyze).with(
          description
        )

        run_command(["analyze", "description1", "--operation=config-file-diffs"])
      end
    end

    describe "#generate-html" do
      it "triggers an HTML export of a system description" do
        expect_any_instance_of(GenerateHtmlTask).to receive(:generate).
          with(an_instance_of(SystemDescription))

        run_command(["generate-html", "description1"])
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

  describe "#upgrade_format" do
    it "triggers the upgrade task for a specific description" do
      expect_any_instance_of(UpgradeFormatTask).to receive(:upgrade).
        with(an_instance_of(SystemDescriptionStore), "foo", {all: false})
      run_command(["upgrade-format", "foo"])
    end

    it "triggers the upgrade task for all descriptions" do
      expect_any_instance_of(UpgradeFormatTask).to receive(:upgrade).
        with(an_instance_of(SystemDescriptionStore), nil, {all: true})
      run_command(["upgrade-format", "--all"])
    end
  end

  describe "#config" do
    it "triggers the config task" do
      expect_any_instance_of(ConfigTask).to receive(:config).
        with("foo", "bar")
      run_command(["config", "foo", "bar"])
    end
  end

  describe ".process_scope_option" do
    it "returns the scopes which are provided" do
      expect(Cli.process_scope_option("os,packages", nil)).to eq(["os", "packages"])
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

  describe ".parse_scopes" do
    it "returns an array with existing scopes" do
      expect(Cli.parse_scopes("os,config-files")).to eq(["os", "config_files"])
    end

    it "raises an error if the provided scope is unknown" do
      expect{
        Cli.parse_scopes("unknown-scope")
      }.to raise_error(Machinery::Errors::UnknownScope, /unknown-scope/)
    end

    it "uses singular in the error message for one scope" do
      expect{
        Cli.parse_scopes("unknown-scope")
      }.to raise_error(Machinery::Errors::UnknownScope, /The following scope is not supported: unknown-scope./)
    end

    it "uses plural in the error message for more than one scope" do
      expect{
        Cli.parse_scopes("unknown-scope,unknown-scope2")
      }.to raise_error(
        Machinery::Errors::UnknownScope,
        /The following scopes are not supported: unknown-scope, unknown-scope2./
      )
    end

    it "raises an error if the scope consists illegal characters" do
      expect{
        Cli.parse_scopes("fd df,u*n")
      }.to raise_error(Machinery::Errors::UnknownScope,
        /The following scopes are not valid: "fd df", "u\*n"\./)
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

      expect(Machinery::Ui).to receive(:error).with(/Machinery experienced an unexpected error. Please file a bug report at https:\/\/github.com\/SUSE\/machinery\/issues\/new.\n/)
      expect(Machinery::Ui).to receive(:error).with(/#{expected_cheetah_out}/)
      begin
        # Actually raise the exception, so we have a backtrace
        raise(Cheetah::ExecutionFailed.new(nil, nil, "This is STDOUT", "This is STDERR"))
      rescue => e
        expect{ Cli.handle_error(e) }.to raise_error(SystemExit)
      end
    end
  end

  private

  def run_command(*args)
    Cli.run(*args)
  rescue SystemExit
  end
end
