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
  capture_machinery_output

  before(:all) do
    # Manually create the exclude option. It depends on the experimental_features option,
    # but that is evaluated when the class is loaded, not when the test is run, so it can't be
    # stubbed.
    if !Cli.commands[:inspect].flags[:exclude]
      Cli.commands[:inspect].flag :exclude, negatable: false,
        desc: "Exclude elements matching the filter criteria"
    end
    if !Cli.commands[:show].flags[:exclude]
      Cli.commands[:show].flag :exclude, negatable: false,
        desc: "Exclude elements matching the filter criteria"
    end
  end

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

  describe "#inspect-container" do
    let(:system) { double(start: nil, stop: nil) }
    before :each do
      allow_any_instance_of(InspectTask).to receive(:inspect_system).
        and_return(create_test_description)
      allow(SystemDescription).to receive(:delete)
      allow(DockerSystem).to receive(:new).and_return(system)
    end

    it "calls the InspectTask" do
      expect_any_instance_of(InspectTask).to receive(:inspect_system).
        with(
          an_instance_of(SystemDescriptionStore),
          system,
          "docker_image_foo",
          an_instance_of(CurrentUser),
          Inspector.all_scopes,
          an_instance_of(Filter),
          {}
        )

      run_command(["inspect-container", "docker_image_foo"])
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

    describe "#system_description_store" do
      it "returns the default store by default" do
        expect(Cli.system_description_store.base_path).to eq(test_base_path)
      end

      it "uses the store specified by MACHINERY_DIR" do
        with_env("MACHINERY_DIR" => "/tmp/machinery") do
          expect(Cli.system_description_store.base_path).to eq("/tmp/machinery")
        end
      end
    end

    describe "#inspect" do
      include_context "machinery test directory"

      before :each do
        allow_any_instance_of(InspectTask).to receive(:inspect_system).
          and_return(description)
        allow(SystemDescription).to receive(:delete)
        allow_any_instance_of(RemoteSystem).to receive(:connect)
      end

      it "shows a note if there are filters for the selected scopes" do
        run_command([
          "inspect", "--exclude=/os/name=bar", "description1", "--scope=os",
        ])

        expect(captured_machinery_output).
          to include("Note: There are filters being applied during inspection. " \
            "(Use `--verbose` option to show the filters)")
      end

      it "does not show a note unless any filters for the selected scopes are set" do
        run_command([
          "inspect", "--exclude=/foo=bar", "description1", "--scope=os",
        ])

        expect(captured_machinery_output).not_to include("Filters are applied during inspection.")
      end

      it "uses the provided host name if specified at the end" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            an_instance_of(RemoteSystem),
            example_host,
            an_instance_of(CurrentUser),
            Inspector.all_scopes,
            an_instance_of(Filter),
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
            an_instance_of(RemoteSystem),
            name,
            an_instance_of(CurrentUser),
            Inspector.all_scopes,
            an_instance_of(Filter),
            {}
           ).
           and_return(description)

        run_command(["inspect", "--name=#{name}", example_host])
      end

      it "uses the host name if no --name is provided" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            an_instance_of(RemoteSystem),
            example_host,
            an_instance_of(CurrentUser),
            Inspector.all_scopes,
            an_instance_of(Filter),
            {}
           ).
          and_return(description)

        run_command(["inspect", example_host])
      end

      it "only inspects the scopes provided" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            an_instance_of(RemoteSystem),
            example_host,
            an_instance_of(CurrentUser),
            ["packages", "repositories"],
            an_instance_of(Filter),
            {}
          ).
          and_return(description)

        run_command(["inspect", "--scope=packages,repositories", example_host])
      end

      it "only inspects a scope once even if it was provided multiple times" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            an_instance_of(RemoteSystem),
            example_host,
            an_instance_of(CurrentUser),
            ["packages"],
            an_instance_of(Filter),
            {}
          ).
          and_return(description)

        run_command(["inspect", "--scope=packages,packages", example_host])
      end

      it "inspects all scopes if no --scope is provided" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system).
          with(
            an_instance_of(SystemDescriptionStore),
            an_instance_of(RemoteSystem),
            example_host,
            an_instance_of(CurrentUser),
            Inspector.all_scopes,
            an_instance_of(Filter),
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
            an_instance_of(RemoteSystem),
            example_host,
            an_instance_of(CurrentUser),
            scope_list,
            an_instance_of(Filter),
            {}
          ).
          and_return(description)

        run_command(["inspect", "--exclude-scope=packages,repositories", example_host])
      end

      it "forwards the --skip-files option to the InspectTask as an unmanaged_files filter" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system) do |_instance, _store,
          _system, _name, _user, _scopes, filter, _options|
          expect(filter.element_filter_for("/unmanaged_files/files/name").matchers["="]).
            to include("/foo/bar", "/baz")
        end.and_return(description)

        run_command(["inspect", "--skip-files=/foo/bar,/baz", example_host])
      end

      it "forwards the global --exclude option to the InspectTask" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system) do |_instance, _store,
          _system, _name, _user, _scopes, filter, _options|
          expect(filter.element_filter_for("/unmanaged_files/files/name").matchers["="]).
            to include("/foo/bar")
        end.and_return(description)

        run_command([
          "inspect",
          "--exclude=/unmanaged_files/files/name=/foo/bar",
          example_host
        ])
      end

      it "adheres to the --remote-user option" do
        expect_any_instance_of(InspectTask).to receive(:inspect_system) do |_instance, _store,
          system, _name, _user, _scopes, _filter, _options|
          expect(system.remote_user).to eq("foo")
        end.and_return(description)

        run_command([
          "inspect",
          "--remote-user=foo",
          example_host
        ])
      end

      describe "--verbose" do
        it "shows no filter message by default" do
          run_command([
            "inspect", example_host,
          ])

          expect(captured_machinery_output).
            not_to include("The following filters are applied during inspection:")
        end

        it "shows the filters when `--verbose` is provided" do
          run_command([
            "inspect", "--verbose", example_host,
          ])

          expect(captured_machinery_output).
            to include("The following filters are applied during inspection:")
          expect(captured_machinery_output).
            to match(/^\/unmanaged_files\/files\/name=.*$/)
        end

        it "shows skip-files filters during inspection" do
          run_command([
            "inspect", "--skip-files=/baz ", "--verbose", example_host,
          ])

          expect(captured_machinery_output).
            to include("The following filters are applied during inspection:")
          expect(captured_machinery_output).
            to match(/\/baz/)
        end
      end

      describe "file extraction" do
        it "doesn't extract files when --extract-files is not specified" do
          expect_any_instance_of(InspectTask).to receive(:inspect_system).
            with(
              an_instance_of(SystemDescriptionStore),
              an_instance_of(RemoteSystem),
              example_host,
              an_instance_of(CurrentUser),
              Inspector.all_scopes,
              an_instance_of(Filter),
              {}
            ).
            and_return(description)

          run_command(["inspect", example_host])
        end

        it "extracts changed config/managed files and umanaged files when --extract-files is specified" do
          expect_any_instance_of(InspectTask).to receive(:inspect_system).
            with(
              an_instance_of(SystemDescriptionStore),
              an_instance_of(RemoteSystem),
              example_host,
              an_instance_of(CurrentUser),
              Inspector.all_scopes,
              an_instance_of(Filter),
              extract_changed_config_files: true,
              extract_unmanaged_files: true,
              extract_changed_managed_files: true
            ).
            and_return(description)

          run_command(["inspect", "--extract-files", example_host])
        end

        it "extracts only changed config files files when --extract-changed-config-files is specified" do
          expect_any_instance_of(InspectTask).to receive(:inspect_system).
            with(
              an_instance_of(SystemDescriptionStore),
              an_instance_of(RemoteSystem),
              example_host,
              an_instance_of(CurrentUser),
              Inspector.all_scopes,
              an_instance_of(Filter),
              extract_changed_config_files: true
            ).
            and_return(description)

          run_command(["inspect", "--extract-changed-config-files", example_host])
        end

        it "extracts only umanaged files when --extract-unmanaged-files is specified" do
          expect_any_instance_of(InspectTask).to receive(:inspect_system).
            with(
              an_instance_of(SystemDescriptionStore),
              an_instance_of(RemoteSystem),
              example_host,
              an_instance_of(CurrentUser),
              Inspector.all_scopes,
              an_instance_of(Filter),
              extract_unmanaged_files: true
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
          with(description, path, enable_dhcp: false, enable_ssh: false)

        run_command(["build", "description1", "--image-dir=#{path}"])
      end
    end

    describe "#serve" do
      it "triggers the serve task" do
        description = create_test_description(json: test_manifest)
        expect_any_instance_of(ServeHtmlTask).to receive(:serve).with(
          description, "0.0.0.0", 3000
        )

        run_command(["serve", "description1", "--ip=0.0.0.0", "--port=3000"])
      end
    end

    describe "#show" do
      it "triggers the show task for packages when scope packages is specified" do
        description = create_test_description(json: test_manifest)
        expect_any_instance_of(ShowTask).to receive(:show).with(
          description, ["packages"], an_instance_of(Filter), show_diffs: false, show_html: false,
          ip: "127.0.0.1", port: anything
        )

        run_command(["show", "description1", "--scope=packages", "--no-pager"])
      end

      context "with --html" do
        it "forwards the specified port and IP" do
          description = create_test_description(json: test_manifest)
          expect_any_instance_of(ShowTask).to receive(:show).with(description, ["packages"],
            an_instance_of(Filter), show_diffs: false, show_html: true, ip: "0.0.0.0", port: 3000)

          run_command(
            ["show", "description1", "--scope=packages", "--html", "--port=3000", "--ip=0.0.0.0"]
          )
        end
      end

      describe "--verbose" do
        before(:each) do
          expect_any_instance_of(ShowTask).to receive(:show)
        end

        it "shows no filter message by default" do
          run_command([
            "show", "description1",
          ])

          expect(captured_machinery_output).
            not_to include("The following filters were applied before showing the description:")
        end

        it "shows the filters when `--verbose` is provided" do
          run_command([
            "show", "description1", "--exclude=/unmanaged_files/files/name=/foo", "--verbose",
          ])

          expect(captured_machinery_output).
            to include("The following filters were applied before showing the description:")
          expect(captured_machinery_output).
            to match(/^\/unmanaged_files\/files\/name=.*$/)
        end

        it "shows the filters which are applied during inspection" do
          description = SystemDescription.load("description1", SystemDescriptionStore.new)
          description.set_filter_definitions("inspect", ["/foo=bar"])
          description.save

          run_command([
            "show", "description1", "--verbose",
          ])

          expect(captured_machinery_output).
            to include("The following filters were applied during inspection:")
          expect(captured_machinery_output).
            to match(/^\/foo=bar/)
        end
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

        run_command(["analyze", "description1", "--operation=foo"])
        expect(captured_machinery_stderr).to include("The operation 'foo' is not supported")
      end

      it "triggers the analyze task" do
        description = create_test_description(json: test_manifest)
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
        with(an_instance_of(SystemDescriptionStore), ["foo"], anything)

      run_command(["remove", "foo"])
    end

    it "triggers the remove task with --all option if given" do
      expect_any_instance_of(RemoveTask).to receive(:remove).
        with(an_instance_of(SystemDescriptionStore), anything, verbose: false, all: true)

      run_command(["remove", "--all"])
    end
  end

  describe "#list" do
    it "triggers the list task" do
      expect_any_instance_of(ListTask).to receive(:list).
        with(an_instance_of(SystemDescriptionStore), anything, anything)
      run_command(["list"])
    end
  end

  describe "#man" do
    it "triggers the man task" do
      expect_any_instance_of(ManTask).to receive(:man)

      run_command(["man"])
    end
  end

  describe "#copy" do
    it "triggers the copy task" do
      expect_any_instance_of(CopyTask).to receive(:copy).
        with(an_instance_of(SystemDescriptionStore), "foo", "bar")
      run_command(["copy", "foo", "bar"])
    end
  end

  describe "#move" do
    it "triggers the move task" do
      expect_any_instance_of(MoveTask).to receive(:move).
        with(an_instance_of(SystemDescriptionStore), "foo", "bar")
      run_command(["move", "foo", "bar"])
    end
  end

  describe "#upgrade_format" do
    it "triggers the upgrade task for a specific description" do
      expect_any_instance_of(UpgradeFormatTask).to receive(:upgrade).
        with(an_instance_of(SystemDescriptionStore), "foo", all: false, force: false)
      run_command(["upgrade-format", "foo"])
    end

    it "triggers the upgrade task for all descriptions" do
      expect_any_instance_of(UpgradeFormatTask).to receive(:upgrade).
        with(an_instance_of(SystemDescriptionStore), nil, all: true, force: false)
      run_command(["upgrade-format", "--all"])
    end

    it "triggers the upgrade task with force option" do
      expect_any_instance_of(UpgradeFormatTask).to receive(:upgrade).
        with(an_instance_of(SystemDescriptionStore), "foo", all: false, force: true)
      run_command(["upgrade-format", "--force", "foo"])
    end
  end

  describe "#config" do
    it "triggers the config task" do
      expect_any_instance_of(ConfigTask).to receive(:config).
        with("foo", "bar")
      run_command(["config", "foo", "bar"])
    end

    it "handles parameter with equal sign syntax" do
      expect_any_instance_of(ConfigTask).to receive(:config).
        with("foo", "bar")
      run_command(["config", "foo=bar"])
    end
  end

  describe ".process_scope_option" do
    it "returns the scopes which are provided" do
      expect(Cli.process_scope_option("os,packages", nil)).to eq(["os", "packages"])
    end

    it "returns sorted scope list" do
      expect(Cli.process_scope_option("packages,users,os", nil)).to eq(
        ["os", "packages", "users"]
      )
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
        /The following scopes are not valid: 'fd df', 'u\*n'\./)
    end
  end

  describe ".handle_error" do
    context "for options" do
      option_parser_exceptions = [OptionParser::MissingArgument, OptionParser::AmbiguousOption]

      option_parser_exceptions.each do |error|
        it "shows a proper error-message for [#{error}]" do
          begin
            raise(error.new)
          rescue => e
            expect { Cli.handle_error(e) }.to raise_error(SystemExit)
          end
          expect(captured_machinery_stderr).to include(
            e.to_s, "Run '#{$0}", "--help' for more information."
          )
        end
      end
    end

    it "shows stderr, stdout and the backtrace for unexpected errors" do
      expected_cheetah_out = <<-EOT.chomp
Machinery experienced an unexpected error.
If this impacts your business please file a service request at https://www.suse.com/mysupport
so that we can assist you on this issue. An active support contract is required.

Cheetah::ExecutionFailed

Error output:
This is STDERR
Standard output:
This is STDOUT

Backtrace:
      EOT

      allow(LocalSystem).to receive(:os).and_return(OsSles12.new)
      begin
        # Actually raise the exception, so we have a backtrace
        raise(Cheetah::ExecutionFailed.new(nil, nil, "This is STDOUT", "This is STDERR"))
      rescue => e
        expect { Cli.handle_error(e) } .to raise_error(SystemExit)
      end
      expect(captured_machinery_stderr).to include(expected_cheetah_out)
    end

    it "shows the usual bug report message for openSUSE" do
      allow(LocalSystem).to receive(:os).and_return(OsOpenSuse13_1.new)

      begin
        raise
      rescue => e
        expect { Cli.handle_error(e) }.to raise_error
      end

      expect(captured_machinery_output).to include(
        "Machinery experienced an unexpected error. Please file a " \
        "bug report at: https://github.com/SUSE/machinery/issues/new\n"
      )
    end

    it "shows a special bug report message for SLES" do
      allow(LocalSystem).to receive(:os).and_return(OsSles12.new)

      begin
        raise
      rescue => e
        expect { Cli.handle_error(e) } .to raise_error
      end

      expect(captured_machinery_output).to include(
        "Machinery experienced an unexpected error.\n" \
        "If this impacts your business please file a service request at " \
        "https://www.suse.com/mysupport\n" \
        "so that we can assist you on this issue. An active support contract is required.\n"
      )
    end
  end

  describe ".check_port_validity" do
    it "checks if a port is invalid below 2" do
      expect { Cli.check_port_validity(1) }.to raise_error(Machinery::Errors::InvalidCommandLine, \
        "Please choose a port between 2 and 65535.")
    end

    it "checks if a port is invalid above 65535" do
      expect { Cli.check_port_validity(65536) }.to raise_error(
        Machinery::Errors::InvalidCommandLine, "Please choose a port between 2 and 65535."
      )
    end

    it "checks if a port is valid between 2 and 65535" do
      expect { Cli.check_port_validity(5000) }.to_not raise_error
    end

    it "checks if a port requires root privileges" do
      expect { Cli.check_port_validity(1000) }.to raise_error(
        Machinery::Errors::InvalidCommandLine, "You need root rights when you want to use a port " \
          "between 2 and 65535."
      )
    end
  end

  private

  def run_command(*args)
    Cli.run(*args)
  rescue SystemExit
  end
end
