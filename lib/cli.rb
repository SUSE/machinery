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

class Cli
  extend GLI::App

  program_desc 'A systems management toolkit for Linux'
  preserve_argv(true)
  @version = Machinery::VERSION + " (system description format version " +
    "#{SystemDescription::CURRENT_FORMAT_VERSION})"
  @config = Machinery::Config.new
  switch :version, negatable: false, desc: "Show version"
  switch :debug, negatable: false, desc: "Enable debug mode"
  switch [:help, :h], negatable: false, desc: "Show help"

  sort_help :manually
  pre do |global_options,command,options,args|
    if global_options[:debug]
      Machinery.logger.level = Logger::DEBUG
    else
      Machinery.logger.level = Logger::INFO
    end

    validate_command_line(command.arguments, args)

    true
  end

  post do |global_options,command,options,args|
    if command.is_a?(GLI::Commands::Help) && !global_options[:version] && ARGV == ["help"]

      Machinery::Ui.puts "\nFor more detailed information, open the man page by typing 'man " \
        "machinery'.\nIf you are unable to find a solution within the man page visit our wiki " \
        "page\nat https://github.com/SUSE/machinery/wiki"

      Machinery::Ui.puts "\nMachinery can show hints which guide through a typical workflow."
      if @config.hints
        Machinery::Ui.puts "These hints can be switched off by " \
          "'#{Hint.program_name} config hints=off'."
      else
        Machinery::Ui.puts "These hints can be switched on by " \
          "'#{Hint.program_name} config hints=on'."
      end

      Hint.print(:get_started)
    end
    Machinery::Ui.close_pager
  end

  GLI::Commands::Help.skips_post = false

  def self.validate_command_line(defined, parsed)
    if defined.any?(&:multiple?) && !defined.any?(&:optional?) && parsed.empty?
      message = "No arguments given. Nothing to do."
      raise GLI::BadCommandLine.new(message)
    elsif !defined.any?(&:multiple?) && parsed.size > defined.size
      parsed_arguments = "#{parsed.size} #{Machinery.pluralize(parsed.size, "argument")}"
      defined_arguments = defined.empty? ? "none" : "only: #{defined.map(&:name).join(", ")}"
      message = "Too many arguments: got #{parsed_arguments}, expected #{defined_arguments}"
      raise GLI::BadCommandLine.new(message)
    end
  end

  def self.buildable_distributions
    distribution_string = ""
    Os.supported_host_systems.each do |distribution|
      distribution_string += "* #{distribution.canonical_name}\n\n"
      distribution_string += distribution.buildable_systems.map(&:canonical_name).join(", ")
      distribution_string += "\n\n"
    end
    distribution_string
  end

  def self.handle_error(e)
    Machinery::Ui.kill_pager

    case e
    when GLI::MissingRequiredArgumentsException
      Machinery::Ui.error("Option --" + e.message)
      exit 1
    when GLI::UnknownCommandArgument, GLI::UnknownGlobalArgument,
      GLI::UnknownCommand, GLI::BadCommandLine,
      OptionParser::MissingArgument, OptionParser::AmbiguousOption
      Machinery::Ui.error e.to_s + "\n\n"
      command = ARGV & @commands.keys.map(&:to_s)
      Machinery::Ui.error "Run '#{Hint.program_name} #{command.first} --help' for more information."
      exit 1
    when Machinery::Errors::MachineryError
      Machinery.logger.error(e.message)
      Machinery::Ui.error e.message
      exit 1
    when SystemExit
      raise
    when SignalException
      Machinery.logger.info "Machinery was aborted with signal #{e.signo}."
      exit 1
    when Errno::ENOSPC
      Machinery::Ui.error("Error: " + e.message)
      exit 1
    else
      if LocalSystem.os.canonical_name.include? ("SUSE Linux Enterprise")
        Machinery::Ui.error "Machinery experienced an unexpected error.\n" \
        "If this impacts your business please file a service request at " \
        "https://www.suse.com/mysupport\n" \
        "so that we can assist you on this issue. An active support contract is required.\n"
      else
        Machinery::Ui.error "Machinery experienced an unexpected error. Please file a " \
          "bug report at: https://github.com/SUSE/machinery/issues/new\n"
      end

      if e.is_a?(Cheetah::ExecutionFailed)
        result = ""
        result << "#{e.message}\n"
        result << "\n"

        if e.stderr && !e.stderr.empty?
          result << "Error output:\n"
          result << "#{e.stderr}\n"
        end

        if e.stdout && !e.stdout.empty?
          result << "Standard output:\n"
          result << "#{e.stdout}\n\n"
        end

        if e.backtrace && !e.backtrace.empty?
          result << "Backtrace:\n"
          result << "#{e.backtrace.join("\n")}\n\n"
        end
        Machinery.logger.error(result)
        Machinery::Ui.error result
        exit 1
      else
        Machinery.logger.error("Machinery experienced an unexpected error:")
        Machinery.logger.error(e.message)
        Machinery.logger.error(e.backtrace.join("\n"))
        raise
      end
    end
    true
  end


  on_error do |e|
    Cli.handle_error(e)
  end

  def self.show_filter_note(scopes, filter)
    if scopes.any? { |scope| !filter.element_filters_for_scope(scope).empty? }
      Machinery::Ui.puts "\nNote: There are filters being applied during inspection. " \
        "(Use `--verbose` option to show the filters)\n\n"
    end
  end

  def self.shift_arg(args, name)
    if !res = args.shift
      raise GLI::BadCommandLine.new("You need to provide the required argument #{name}.")
    end
    res
  end

  def self.process_scope_option(scopes, exclude_scopes)
    if scopes
      if exclude_scopes
        # scope and exclude-scope
        raise Machinery::Errors::InvalidCommandLine.new( "You cannot provide the --scope and --exclude-scope option at the same time.")
      else
        # scope only
        scope_list = parse_scopes(scopes)
      end
    else
      if exclude_scopes
        # exclude-scope only
        scope_list = Inspector.all_scopes - parse_scopes(exclude_scopes)
      else
        # neither scope nor exclude-scope
        scope_list = Inspector.all_scopes
      end
    end
    if scope_list.empty?
      raise Machinery::Errors::InvalidCommandLine.new( "No scopes to process. Nothing to do.")
    end
    scope_list
  end

  def self.parse_scopes(scope_string)
    unknown_scopes = []
    invalid_scopes = []
    scopes = []

    scope_string.split(",").each do |scope|
      if !(scope =~ /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/)
        invalid_scopes << scope
        next
      end

      # convert cli scope naming to internal one
      scope.tr!("-", "_")

      if Inspector.all_scopes.include?(scope) && Renderer.for(scope)
        scopes << scope
      else
        unknown_scopes << scope
      end
    end

    if invalid_scopes.length > 0
      form = invalid_scopes.length > 1 ? "scopes are" : "scope is"
      raise Machinery::Errors::UnknownScope.new(
        "The following #{form} not valid:" \
          " '#{invalid_scopes.join("', '")}'." \
          " Scope names must start with a letter and contain only lowercase" \
          " letters and digits separated by dashes ('-')."
      )
    end

    if unknown_scopes.length > 0
      form = unknown_scopes.length > 1 ? "scopes are" : "scope is"
      raise Machinery::Errors::UnknownScope.new(
        "The following #{form} not supported: " \
          "#{Machinery::Ui.internal_scope_list_to_string(unknown_scopes)}. " \
        "Valid scopes are: #{AVAILABLE_SCOPE_LIST}."
      )
    end

    Inspector.sort_scopes(scopes.uniq)
  end

  def self.supports_filtering(command)
    if @config.experimental_features
      command.flag :exclude, negatable: false, desc: "Exclude elements matching the filter criteria"
    end
  end

  def self.check_port_validity(port)
    if port < 2 || port > 65535
      raise Machinery::Errors::InvalidCommandLine.new("Please choose a port between 2 and " \
        "65535.")
    else
      if port >= 2 && port <= 1023 && !CurrentUser.new.is_root?
        raise Machinery::Errors::InvalidCommandLine.new("You need root rights when you want " \
          "to use a port between 2 and 65535.")
      end
    end
  end

  AVAILABLE_SCOPE_LIST = Machinery::Ui.internal_scope_list_to_string(
    Inspector.all_scopes
  )

  desc "Analyze system description"
  long_desc <<-LONGDESC
    Analyze stored system description.

    The supported operations are:

    - config-file-diffs: Generate diffs against the original version from
      the package for the modified config files
  LONGDESC
  arg "NAME"
  command "analyze" do |c|
    c.flag [:operation, :o], type: String, required: true,
      desc: "The analyze operation to perform", arg_name: "OPERATION"

    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME")
      description = SystemDescription.load(name, system_description_store)

      case options[:operation]
        when "config-file-diffs"
          task = AnalyzeConfigFileDiffsTask.new
          task.analyze(description)
          Hint.print(:show_analyze_data, name: name)
        else
          raise Machinery::Errors::InvalidCommandLine.new(
            "The operation '#{options[:operation]}' is not supported. " \
            "Valid operations are: config-file-diffs."
          )
      end
    end
  end



  desc "Build image from system description"
  long_desc <<-LONGDESC
    Build image from a given system description and store it to the given
    location.

    The following combinations of build hosts and targets are supported:

    #{buildable_distributions}
  LONGDESC
  arg "NAME"
  command "build" do |c|
    c.flag ["image-dir", :i], type: String, required: true,
      desc: "Store the image under the specified path", arg_name: "DIRECTORY"
    c.switch ["enable-dhcp", :d], required: false, negatable: false,
      desc: "Enable DCHP client on first network card of built image"
    c.switch ["enable-ssh", :s], required: false, negatable: false,
      desc: "Enable SSH service in built image"

    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME")
      description = SystemDescription.load(name, system_description_store)

      task = BuildTask.new
      task.build(
        description, File.expand_path(options["image-dir"]),
        enable_dhcp: options["enable-dhcp"], enable_ssh: options["enable-ssh"]
      )
    end
  end



  desc "Compare system descriptions"
  long_desc <<-LONGDESC
    Compare system descriptions stored under specified names.

    Multiple scopes can be passed as comma-separated list. If no specific scopes
    are given, all scopes are compared.

    Available scopes: #{AVAILABLE_SCOPE_LIST}
  LONGDESC
  arg "NAME1"
  arg "NAME2"
  command "compare" do |c|
    c.flag [:scope, :s], type: String, required: false,
      desc: "Compare specified scopes", arg_name: "SCOPE_LIST"
    c.flag ["exclude-scope", :e], type: String, required: false,
      desc: "Exclude specified scopes", arg_name: "SCOPE_LIST"
    c.switch "show-all", required: false, negatable: false,
      desc: "Show also common properties"
    if @config.experimental_features
      c.flag [:port, :p], type: Integer, required: false, default_value: @config.http_server_port,
        desc: "Listen on port PORT. Ports can be selected in a range between 2-65535. Ports between
          2 and 1023 can only be chosen when `machinery` will be executed as `root` user.",
          arg_name: "PORT"
      c.flag [:ip, :i], type: String, required: false, default_value: "127.0.0.1",
        desc: "Listen on ip address IP. It's only possible to use an IP address (or hostnames
          resolving to an IP address) which is assigned to a network interface on the local
          machine.", arg_name: "IP"
      c.switch "html", required: false, negatable: false,
        desc: "Open comparison in HTML format in your web browser."
    end
    c.switch "pager", required: false, default_value: true,
      desc: "Pipe output into a pager"

    c.action do |global_options,options,args|
      Machinery::Ui.use_pager = options[:pager]

      name1 = shift_arg(args, "NAME1")
      name2 = shift_arg(args, "NAME2")

      check_port_validity(options[:port]) if options[:html]

      store = system_description_store
      description1 = SystemDescription.load(name1, store)
      description2 = SystemDescription.load(name2, store)
      scope_list = process_scope_option(options[:scope], options["exclude-scope"])

      task = CompareTask.new
      opts = {
        show_html: options["html"],
        show_all: options["show-all"],
        ip: options["ip"],
        port: options["port"]
      }
      task.compare(description1, description2, scope_list, opts)
    end
  end



  desc "Copy system description"
  long_desc <<-LONGDESC
    Copy a system description.

    The system description is copied and stored under the provided name.
  LONGDESC
  arg "FROM_NAME"
  arg "TO_NAME"
  command "copy" do |c|
    c.action do |global_options,options,args|
      from = shift_arg(args, "FROM_NAME")
      to = shift_arg(args, "TO_NAME")
      task = CopyTask.new
      task.copy(system_description_store, from, to)
    end
  end

  desc "Move system description"
  long_desc <<-LONGDESC
    Move a system description.

    The system description name is changed to the provided name.
  LONGDESC
  arg "FROM_NAME"
  arg "TO_NAME"
  command "move" do |c|
    c.action do |_global_options, _options, args|
      from = shift_arg(args, "FROM_NAME")
      to = shift_arg(args, "TO_NAME")
      task = MoveTask.new
      task.move(system_description_store, from, to)
    end
  end


  desc "Deploy image to OpenStack cloud"
  long_desc <<-LONGDESC
    Deploy system description as image to OpenStack cloud.

    The image will be deployed to the OpenStack cloud. If no --image-dir is
    specified an image will be built from the description before deployment.
  LONGDESC
  arg "NAME"
  command "deploy" do |c|
    c.flag ["cloud-config", :c], type: String, required: true, arg_name: "FILE",
      desc: "Path to file where the cloud config (openrc.sh) is located"
    c.flag ["image-dir", :i], type: String, required: false,
      desc: "Directory where the image is located", arg_name: "DIRECTORY"
    c.switch [:insecure, :s], required: false, negatable: false,
      desc: "Explicitly allow glanceclient to perform 'insecure SSL' (https) requests."
    c.flag ["cloud-image-name", :n], type: String, required: false,
      desc: "Name of the image in the cloud", arg_name: "NAME"

    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME")
      description = SystemDescription.load(name, system_description_store)

      task = DeployTask.new
      opts = {
          image_name: options[:cloud_image_name],
          insecure: options[:insecure]
      }
      opts[:image_dir] = File.expand_path(options["image-dir"]) if options["image-dir"]
      task.deploy(description, File.expand_path(options["cloud-config"]), opts)
    end
  end



  desc  "Export system description as KIWI image description"
  long_desc <<-LONGDESC
    Export system description as KIWI image description.

    The description will be placed in a subdirectory at the given location. The image format in
    the description is 'vmx'.
  LONGDESC
  arg "NAME"
  command "export-kiwi" do |c|
    c.flag ["kiwi-dir", :k], type: String, required: true,
      desc: "Location where the description will be stored", arg_name: "DIRECTORY"
    c.switch :force, default_value: false, required: false, negatable: false,
      desc: "Overwrite existing description"

    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME")
      description = SystemDescription.load(name, system_description_store)
      exporter = KiwiConfig.new(description)

      task = ExportTask.new(exporter)
      task.export(
        File.expand_path(options["kiwi-dir"]),
        force: options[:force]
      )
    end
  end

  desc "Export system description as AutoYaST profile"
  long_desc <<-LONGDESC
    Export system description as AutoYaST profile

    The profile will be placed in a subdirectory at the given location by the 'autoyast-dir'
    option.
  LONGDESC
  arg "NAME"
  command "export-autoyast" do |c|
    c.flag ["autoyast-dir", :a], type: String, required: true,
      desc: "Location where the autoyast profile will be stored", arg_name: "DIRECTORY"
    c.switch :force, default_value: false, required: false, negatable: false,
      desc: "Overwrite existing profile"

    c.action do |_global_options, options, args|
      name = shift_arg(args, "NAME")
      description = SystemDescription.load(name, system_description_store)
      exporter = Autoyast.new(description)

      task = ExportTask.new(exporter)
      task.export(
        File.expand_path(options["autoyast-dir"]),
        force: options[:force]
      )
    end
  end

  def self.define_inspect_command_options(c)
    c.flag [:name, :n], type: String, required: false, arg_name: "NAME",
      desc: "Store system description under the specified name"
    c.flag [:scope, :s], type: String, required: false,
      desc: "Show specified scopes", arg_name: "SCOPE_LIST"
    c.flag ["exclude-scope", :e], type: String, required: false,
      desc: "Exclude specified scopes", arg_name: "SCOPE_LIST"
    c.flag "skip-files", required: false, negatable: false,
      desc: "Do not consider given files or directories during inspection. " \
        "Either provide one file or directory name or a list of names separated by commas."
    c.switch ["extract-files", :x], required: false, negatable: false,
      desc: "Extract changed configuration files and unmanaged files from inspected system"
    c.switch "extract-changed-config-files", required: false, negatable: false,
      desc: "Extract changed configuration files from inspected system"
    c.switch "extract-unmanaged-files", required: false, negatable: false,
      desc: "Extract unmanaged files from inspected system"
    c.switch "extract-changed-managed-files", required: false, negatable: false,
      desc: "Extract changed managed files from inspected system"
    c.switch :show, required: false, negatable: false,
      desc: "Print inspection result"
    c.switch :verbose, required: false, negatable: false,
      desc: "Display the filters which are used during inspection"
  end

  def self.parse_inspect_command_options(host, options)
    scope_list = process_scope_option(options[:scope], options["exclude-scope"])
    name = options[:name] || host


    if !scope_list.empty?
      inspected_scopes = " for #{Machinery::Ui.internal_scope_list_to_string(scope_list)}"
    end
    Machinery::Ui.puts "Inspecting #{host}#{inspected_scopes}..."

    inspect_options = {}
    if options["show"]
      inspect_options[:show] = true
    end
    if options["verbose"]
      inspect_options[:verbose] = true
    end
    if options["extract-files"] || options["extract-changed-config-files"]
      inspect_options[:extract_changed_config_files] = true
    end
    if options["extract-files"] || options["extract-changed-managed-files"]
      inspect_options[:extract_changed_managed_files] = true
    end
    if options["extract-files"] || options["extract-unmanaged-files"]
      inspect_options[:extract_unmanaged_files] = true
    end

    filter = FilterOptionParser.parse("inspect", options)

    if options["verbose"] && !filter.empty?
      Machinery::Ui.puts "\nThe following filters are applied during inspection:"
      Machinery::Ui.puts filter.to_array.join("\n") + "\n\n"
    else
      show_filter_note(scope_list, filter)
    end

    [name, scope_list, inspect_options, filter]
  end

  desc "Inspect running system"
  long_desc <<-LONGDESC
    Inspect running system and generate system descripton from inspected data.

    Multiple scopes can be passed as comma-separated list. If no specific scopes
    are given, all scopes are inspected.

    Available scopes: #{AVAILABLE_SCOPE_LIST}
  LONGDESC
  arg "HOSTNAME"
  command "inspect" do |c|
    supports_filtering(c)
    define_inspect_command_options(c)
    c.flag ["remote-user", :r], type: String, required: false, default_value: @config.remote_user,
      desc: "Defines the user which is used to access the inspected system via SSH."\
        "This user needs sudo access on the remote machine or be root.", arg_name: "USER"

    c.action do |_global_options, options, args|
      host = shift_arg(args, "HOSTNAME")
      system = System.for(host, options["remote-user"])
      inspector_task = InspectTask.new

      name, scope_list, inspect_options, filter = parse_inspect_command_options(host, options)

      inspector_task.inspect_system(
        system_description_store,
        system,
        name,
        CurrentUser.new,
        scope_list,
        filter,
        inspect_options
      )

      Hint.print(:show_data, name: name)

      if !options["extract-files"] || Inspector.all_scopes.count != scope_list.count
        Hint.print(:do_complete_inspection, name: name, host: host)
      end
    end
  end

  desc "Inspect container image"
  long_desc <<-LONGDESC
    Inspect container image and generate system descripton from inspected data.

    Multiple scopes can be passed as comma-separated list. If no specific scopes
    are given, all scopes are inspected.

    Available scopes: #{AVAILABLE_SCOPE_LIST}
  LONGDESC
  arg "<IMAGENAME|IMAGEID>"
  command "inspect-container" do |c|
    supports_filtering(c)
    define_inspect_command_options(c)
    c.switch ["docker", :d], required: true, negatable: false,
      desc: "Inspect a docker container"

    c.action do |_global_options, options, args|
      image = shift_arg(args, "<IMAGENAME|IMAGEID>")
      system = DockerSystem.new(image)
      inspector_task = InspectTask.new

      name, scope_list, inspect_options, filter = parse_inspect_command_options(image, options)

      begin
        system.start
        inspector_task.inspect_system(
          system_description_store,
          system,
          name,
          CurrentUser.new,
          scope_list,
          filter,
          inspect_options
        )
      ensure
        system.stop
      end


      Hint.print(:show_data, name: name)

      if !options["extract-files"] || Inspector.all_scopes.count != scope_list.count
        Hint.print(:do_complete_inspection, name: name, docker_container: image)
      end
    end
  end

  desc "List system descriptions"
  long_desc <<-LONGDESC
    List all system descriptions and their stored scopes, when no NAME parameter is specified.

    List only the specified system descriptions and its stored scopes, when NAME parameter is given.

    The date of modification for each scope can be shown with the verbose
    option.
  LONGDESC
  arg "NAME", [:multiple, :optional]

  command "list" do |c|
    c.switch :verbose, required: false, negatable: false,
      desc: "Display additional information about origin of scopes"
    c.switch :short, required: false, negatable: false,
      desc: "List only description names"

    c.action do |global_options,options,args|
      task = ListTask.new
      task.list(system_description_store, args, options)
    end
  end

  desc "Shows man page"
  long_desc <<-LONGDESC
    Shows the man page of the machinery tool.

  LONGDESC
  command "man" do |c|
    c.action do
      task = ManTask.new
      task.man
    end
  end



  desc "Remove system descriptions"
  long_desc <<-LONGDESC
    Removes all specified descriptions stored under the specified names.

    The success of a removal can be shown with the verbose option.
  LONGDESC
  arg "NAME", [:multiple, :optional]

  command "remove" do |c|
    c.switch :all, negatable: false,
      desc: "Remove all system descriptions"
    c.switch :verbose, required: false, negatable: false,
      desc: "Explain what is being done"

    c.action do |global_options,options,args|
      if !options[:all] && args.empty?
        raise GLI::BadCommandLine.new, "You need to either specify `--all` or a list of system descriptions"
      end

      task = RemoveTask.new
      task.remove(system_description_store, args, verbose: options[:verbose], all: options[:all])
    end
  end



  desc "Show system description"
  long_desc <<-LONGDESC
    Show system description stored under the specified name.

    Multiple scopes can be passed as comma-separated list. If no specific scopes
    are given, all scopes are shown.

    Available scopes: #{AVAILABLE_SCOPE_LIST}
  LONGDESC
  arg "NAME"
  command "show" do |c|
    supports_filtering(c)
    c.flag [:scope, :s], type: String, required: false,
      desc: "Show specified scopes", arg_name: "SCOPE_LIST"
    c.flag ["exclude-scope", :e], type: String, required: false,
      desc: "Exclude specified scopes", arg_name: "SCOPE_LIST"
    c.flag [:port, :p], type: Integer, required: false, default_value: @config.http_server_port,
      desc: "Listen on port PORT. Ports can be selected in a range between 2-65535. Ports between
        2 and 1023 can only be chosen when `machinery` will be executed as `root` user.",
        arg_name: "PORT"
    c.flag [:ip, :i], type: String, required: false, default_value: "127.0.0.1",
      desc: "Listen on ip address IP. It's only possible to use an IP address (or hostnames
        resolving to an IP address) which is assigned to a network interface on the local
        machine.", arg_name: "IP"
    c.switch "pager", required: false, default_value: true,
      desc: "Pipe output into a pager"
    c.switch "show-diffs", required: false, negatable: false,
      desc: "Show diffs of configuration files changes."
    c.switch "html", required: false, negatable: false,
      desc: "Open system description in HTML format in your web browser."
    c.switch "verbose", required: false, negatable: false,
      desc: "Show the filters that were applied before showing the description."

    c.action do |global_options,options,args|
      Machinery::Ui.use_pager = options["pager"]

      name = shift_arg(args, "NAME")
      if name == "localhost" && !CurrentUser.new.is_root?
        Machinery::Ui.puts "You need root rights to access the system description of your locally inspected system."
      end

      check_port_validity(options[:port]) if options[:html]

      description = SystemDescription.load(name, system_description_store)
      scope_list = process_scope_option(options[:scope], options["exclude-scope"])

      filter = FilterOptionParser.parse("show", options)

      inspected_filters = description.filter_definitions("inspect")

      if options[:verbose]
        if !inspected_filters.empty?
          Machinery::Ui.puts "\nThe following filters were applied during inspection:"
          Machinery::Ui.puts inspected_filters.join("\n") + "\n\n"
        end

        if !filter.empty?
          Machinery::Ui.puts "\nThe following filters were applied before showing the description:"
          Machinery::Ui.puts filter.to_array.join("\n") + "\n\n"
        end
      end

      task = ShowTask.new
      opts = {
        show_diffs: options["show-diffs"],
        show_html: options["html"],
        ip: options["ip"],
        port: options["port"]
      }
      task.show(description, scope_list, filter, opts)
    end
  end


  desc "Validate system description"
  long_desc <<-LONGDESC
    Validate system description stored under the specified name.
  LONGDESC
  arg "NAME"
  command "validate" do |c|
    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME")
      if name == "localhost" && !CurrentUser.new.is_root?
        Machinery::Ui.puts "You need root rights to access the system description of your locally inspected system."
      end

      task = ValidateTask.new
      task.validate(system_description_store, name)
    end
  end

  desc "Upgrade format of system description"
  long_desc <<-LONGDESC
    Upgrade the format of one or all system descriptions.
  LONGDESC
  arg "NAME"
  command "upgrade-format" do |c|
    c.switch :all, negatable: false,
      desc: "Upgrade all system descriptions"
    c.switch :force, default_value: false, required: false, negatable: false,
      desc: "Keep backup after migration and ingnore validation errors"

    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME") if !options[:all]

      task = UpgradeFormatTask.new
      task.upgrade(
        system_description_store,
        name,
        all: options[:all],
        force: options[:force]
      )
    end
  end

  desc "Show or change machinery's configuration"
  long_desc <<-LONGDESC
    Show or change machinery's configuration.

    The value of a key is shown when no value argument is passed.
    If neither the key argument nor the value argument are specified a list of all keys and their values are shown.

    ALTERNATIVE SYNOPSIS:

    machinery [global options] config [KEY][=VALUE]
  LONGDESC
  arg "KEY", :optional
  arg "VALUE", :optional
  command "config" do |c|
    c.action do |global_options,options,args|
      if args[0] && args[0].include?("=")
        if args[1]
          raise GLI::BadCommandLine, "Too many arguments: got 2 arguments, expected only: KEY=VALUE"
        else
          key, value = args[0].split("=")
        end
      else
        key = args[0]
        value = args[1]
      end

      task = ConfigTask.new
      task.config(key, value)

      if key == "hints" && (value == "false" || value == "off")
        Machinery::Ui.puts "Hints can be switched on again by " \
          "'#{Hint.program_name} config hints=on'."
      end
    end
  end

  desc "Start a webserver serving an HTML view of a system description"
  long_desc <<-LONGDESC
    Starts a web server which serves an HTML view for the given system description.
  LONGDESC
  arg "NAME"
  command "serve" do |c|
    c.flag [:port, :p], type: Integer, required: false,
      default_value: Machinery::Config.new.http_server_port,
      desc: "Listen on port PORT. Ports can be selected in a range between 2-65535. Ports between
        2 and 1023 can only be chosen when `machinery` will be executed as `root` user.",
        arg_name: "PORT"
    c.flag [:ip, :i], type: String, required: false, default_value: "127.0.0.1",
      desc: "Listen on ip address IP. It's only possible to use an IP address (or hostnames
        resolving to an IP address) which is assigned to a network interface on the local
        machine.", arg_name: "IP"

    c.action do |_global_options, options, args|
      name = shift_arg(args, "NAME")

      check_port_validity(options[:port])

      description = SystemDescription.load(name, system_description_store)
      task = ServeHtmlTask.new
      task.serve(description, options[:ip], options[:port])
    end
  end

  if @config.experimental_features
    desc "Containerize a system description"
    long_desc <<-LONGDESC
      Detects workloads from a system description and creates a recommendation for a corresponding
      container setup
    LONGDESC
    arg "NAME"
    command "containerize" do |c|
      c.flag ["output-dir", :o], type: String, required: true,
        desc: "Location where the container files will be stored", arg_name: "DIRECTORY"

      c.action do |_global_options, options, args|
        name = shift_arg(args, "NAME")
        description = SystemDescription.load(name, system_description_store)
        task = ContainerizeTask.new
        task.containerize(description, File.expand_path(options["output-dir"]))
      end
    end
  end

  def self.system_description_store
    if ENV.has_key?("MACHINERY_DIR")
      SystemDescriptionStore.new(ENV["MACHINERY_DIR"])
    else
      SystemDescriptionStore.new
    end
  end
end
