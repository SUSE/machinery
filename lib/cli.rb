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
  switch :version, :negatable => false, :desc => "Show version"
  switch :debug, :negatable => false, :desc => "Enable debug mode"
  switch [:help, :h], :negatable => false, :desc => "Show help"

  sort_help :manually
  pre do |global_options,command,options,args|
    if global_options[:debug]
      Machinery.logger.level = Logger::DEBUG
    else
      Machinery.logger.level = Logger::INFO
    end
  end

  post do |global_options,command,options,args|
    if command.is_a?(GLI::Commands::Help) && !global_options[:version]

      Machinery::Ui.puts "\nMachinery can show hints which guide through a typical workflow."
      if Machinery::Config.new.hints
        Machinery::Ui.puts "These hints can be switched off by '#{$0} config hints off'."
      else
        Machinery::Ui.puts "These hints can be switched on by '#{$0} config hints on'."
      end

      Hint.get_started
    end
  end

  GLI::Commands::Help.skips_post = false

  def self.handle_error(e)
    case e
    when GLI::UnknownCommandArgument, GLI::UnknownGlobalArgument,
        GLI::UnknownCommand, GLI::BadCommandLine, OptionParser::MissingArgument
      Machinery::Ui.error e.to_s + "\n\n"
      command = ARGV & @commands.keys.map(&:to_s)
      run(command << "--help")
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
    else
      Machinery::Ui.error "Machinery experienced an unexpected error. Please file a " \
        "bug report at https://github.com/SUSE/machinery/issues/new.\n"
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
          " \"#{invalid_scopes.join("\", \"")}\"." \
          " Scope names must start with a letter and contain only lowercase" \
          " letters and digits separated by dashes (\"-\")."
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

    scopes.uniq
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
  command :analyze do |c|
    c.flag [:operation, :o], :type => String, :required => true,
      :desc => "The analyze operation to perform", :arg_name => "OPERATION"

    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME")
      store = SystemDescriptionStore.new
      description = SystemDescription.load(name, store)

      case options[:operation]
        when "config-file-diffs"
          task = AnalyzeConfigFileDiffsTask.new
          task.analyze(description)
          Hint.show_analyze_data(name: name)
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
  LONGDESC
  arg "NAME"
  command :build do |c|
    c.flag ["image-dir", :i], :type => String, :required => true,
      :desc => "Store the image under the specified path", :arg_name => "DIRECTORY"
    c.switch ["enable-dhcp", :d], :required => false, :negatable => false,
      :desc => "Enable DCHP client on first network card of built image"
    c.switch ["enable-ssh", :s], :required => false, :negatable => false,
      :desc => "Enable SSH service in built image"

    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME")
      store = SystemDescriptionStore.new
      description = SystemDescription.load(name, store)

      task = BuildTask.new
      task.build(description, File.expand_path(options["image-dir"]), {:enable_dhcp => options["enable-dhcp"], :enable_ssh => options["enable-ssh"]})
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
  command :compare do |c|
    c.flag [:scope, :s], :type => String, :required => false,
      :desc => "Compare specified scopes", :arg_name => "SCOPE_LIST"
    c.flag ["exclude-scope", :e], :type => String, :required => false,
      :desc => "Exclude specified scopes", :arg_name => "SCOPE_LIST"
    c.switch "show-all", :required => false, :negatable => false,
      :desc => "Show also common properties"
    c.switch "pager", :required => false, :default_value => true,
      :desc => "Pipe output into a pager"

    c.action do |global_options,options,args|
      name1 = shift_arg(args, "NAME1")
      name2 = shift_arg(args, "NAME2")
      store = SystemDescriptionStore.new
      description1 = SystemDescription.load(name1, store)
      description2 = SystemDescription.load(name2, store)
      scope_list = process_scope_option(options[:scope], options["exclude-scope"])

      task = CompareTask.new
      opts = {
          show_all: options["show-all"],
          no_pager: !options["pager"]
      }
      task.compare(description1, description2, scope_list, opts)
    end
  end



  desc "Copy system description"
  long_desc <<-LONGDESC
    Copy a system description.

    The system description is copied and stored under the provided name.
  LONGDESC
  arg_name "FROM_NAME TO_NAME"
  command :copy do |c|
    c.action do |global_options,options,args|
      from = shift_arg(args, "FROM_NAME")
      to = shift_arg(args, "TO_NAME")
      store = SystemDescriptionStore.new
      task = CopyTask.new
      task.copy(store, from, to)
    end
  end



  desc "Deploy image to OpenStack cloud"
  long_desc <<-LONGDESC
    Deploy system description as image to OpenStack cloud.

    The image will be deployed to the OpenStack cloud. If no --image-dir is
    specified an image will be built from the description before deployment.
  LONGDESC
  arg "NAME"
  command :deploy do |c|
    c.flag ["cloud-config", :c], :type => String, :required => true, :arg_name => "FILE",
      :desc => "Path to file where the cloud config (openrc.sh) is located"
    c.flag ["image-dir", :i], :type => String, :required => false,
      :desc => "Directory where the image is located", :arg_name => "DIRECTORY"
    c.switch [:insecure, :s], :required => false, :negatable => false,
      :desc => "Explicitly allow glanceclient to perform 'insecure SSL' (https) requests."
    c.flag ["cloud-image-name", :n], :type => String, :required => false,
      :desc => "Name of the image in the cloud", :arg_name => "NAME"

    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME")
      store = SystemDescriptionStore.new
      description = SystemDescription.load(name, store)

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
    c.flag ["kiwi-dir", :k], :type => String, :required => true,
      :desc => "Location where the description will be stored", :arg_name => "DIRECTORY"
    c.switch :force, :default_value => false, :required => false, :negatable => false,
      :desc => "Overwrite existing description"

    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME")
      store = SystemDescriptionStore.new
      description = SystemDescription.load(name, store)
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
      store = SystemDescriptionStore.new
      description = SystemDescription.load(name, store)
      exporter = Autoyast.new(description)

      task = ExportTask.new(exporter)
      task.export(
        File.expand_path(options["autoyast-dir"]),
        force: options[:force]
      )
    end
  end



  desc "Inspect running system"
  long_desc <<-LONGDESC
    Inspect running system and generate system descripton from inspected data.

    Multiple scopes can be passed as comma-separated list. If no specific scopes
    are given, all scopes are inspected.

    Available scopes: #{AVAILABLE_SCOPE_LIST}
  LONGDESC
  arg "HOSTNAME"
  command :inspect do |c|
    c.flag [:name, :n], :type => String, :required => false, :arg_name => "NAME",
      :desc => "Store system description under the specified name"
    c.flag [:scope, :s], :type => String, :required => false,
      :desc => "Show specified scopes", :arg_name => "SCOPE_LIST"
    c.flag ["exclude-scope", :e], :type => String, :required => false,
      :desc => "Exclude specified scopes", :arg_name => "SCOPE_LIST"
    c.switch ["extract-files", :x], :required => false, :negatable => false,
      :desc => "Extract changed configuration files and unmanaged files from inspected system"
    c.switch "extract-changed-config-files", :required => false, :negatable => false,
      :desc => "Extract changed configuration files from inspected system"
    c.switch "extract-unmanaged-files", :required => false, :negatable => false,
      :desc => "Extract unmanaged files from inspected system"
    c.switch "extract-changed-managed-files", :required => false, :negatable => false,
      :desc => "Extract changed managed files from inspected system"
    c.switch :show, :required => false, :negatable => false,
      :desc => "Print inspection result"

    c.action do |global_options,options,args|
      host = shift_arg(args, "HOSTNAME")
      store = SystemDescriptionStore.new
      inspector_task = InspectTask.new
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
      if options["extract-files"] || options["extract-changed-config-files"]
        inspect_options[:extract_changed_config_files] = true
      end
      if options["extract-files"] || options["extract-changed-managed-files"]
        inspect_options[:extract_changed_managed_files] = true
      end
      if options["extract-files"] || options["extract-unmanaged-files"]
        inspect_options[:extract_unmanaged_files] = true
      end

      inspector_task.inspect_system(
        store, host, name, CurrentUser.new, scope_list, inspect_options
      )

      Hint.show_data(:name => name)

      if !options["extract-files"] || Inspector.all_scopes.count != scope_list.count
        Hint.do_complete_inspection(:name => name, :host => host)
      end
    end
  end



  desc "List system descriptions"
  long_desc <<-LONGDESC
    List system descriptions and their stored scopes.

    The date of modification for each scope can be shown with the verbose
    option.
  LONGDESC
  command :list do |c|
    c.switch :verbose, :required => false, :negatable => false,
      :desc => "Display additional information about origin of scopes"
    c.switch :quick, :required => false, :negatable => false,
      :desc => "Show quick list without details"

    c.action do |global_options,options,args|
      store = SystemDescriptionStore.new
      task = ListTask.new
      task.list(store, options)
    end
  end



  desc "Remove system description"
  long_desc <<-LONGDESC
    Remove system description stored under the specified name.

    The success of a removal can be shown with the verbose option.
  LONGDESC
  arg "NAME"
  command :remove do |c|
    c.switch :all, :negatable => false,
      :desc => "Remove all system descriptions"
    c.switch :verbose, :required => false, :negatable => false,
      :desc => "Explain what is being done"

    c.action do |global_options,options,args|

      store = SystemDescriptionStore.new
      task = RemoveTask.new
      task.remove(store, args, :verbose => options[:verbose], :all => options[:all])
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
  command :show do |c|
    c.flag [:scope, :s], :type => String, :required => false,
      :desc => "Show specified scopes", :arg_name => "SCOPE_LIST"
    c.flag ["exclude-scope", :e], :type => String, :required => false,
      :desc => "Exclude specified scopes", :arg_name => "SCOPE_LIST"
    c.switch "pager", :required => false, :default_value => true,
      :desc => "Pipe output into a pager"
    c.switch "show-diffs", :required => false, :negatable => false,
      :desc => "Show diffs of configuration files changes."
    c.switch "html", :required => false, :negatable => false,
      :desc => "Open system description in HTML format in your web browser."

    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME")
      if name == "localhost" && !CurrentUser.new.is_root?
        Machinery::Ui.puts "You need root rights to access the system description of your locally inspected system."
      end

      store = SystemDescriptionStore.new
      description = SystemDescription.load(name, store)
      scope_list = process_scope_option(options[:scope], options["exclude-scope"])


      task = ShowTask.new
      opts = {
          no_pager:   !options["pager"],
          show_diffs: options["show-diffs"],
          show_html:  options["html"]
      }
      task.show(description, scope_list, opts)
    end
  end


  desc "Validate system description"
  long_desc <<-LONGDESC
    Validate system description stored under the specified name.
  LONGDESC
  arg "NAME"
  command :validate do |c|
    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME")
      if name == "localhost" && !CurrentUser.new.is_root?
        Machinery::Ui.puts "You need root rights to access the system description of your locally inspected system."
      end

      store = SystemDescriptionStore.new
      task = ValidateTask.new
      task.validate(store, name)
    end
  end

  desc "Upgrade format of system description"
  long_desc <<-LONGDESC
    Upgrade the format of one or all system descriptions.
  LONGDESC
  arg "NAME"
  command "upgrade-format" do |c|
    c.switch :all, :negatable => false,
      :desc => "Upgrade all system descriptions"
    c.switch :force, :default_value => false, :required => false, :negatable => false,
      :desc => "Keep backup after migration and ingnore validation errors"

    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME") if !options[:all]

      store = SystemDescriptionStore.new
      task = UpgradeFormatTask.new
      task.upgrade(
        store,
        name,
        :all => options[:all],
        :force => options[:force]
      )
    end
  end

  desc "Generate an HTML view for a system description"
  long_desc <<-LONGDESC
    Generates an HTML view for a system description.
  LONGDESC
  arg "NAME"
  command "generate-html" do |c|
    c.action do |global_options,options,args|
      name = shift_arg(args, "NAME")

      store = SystemDescriptionStore.new
      description = SystemDescription.load(name, store)
      task = GenerateHtmlTask.new
      task.generate(description)
    end
  end

  desc "Show or change machinery's configuration"
  long_desc <<-LONGDESC
    Show or change machinery's configuration.

    The value of a key is shown when no value argument is passed.
    If neither the key argument nor the value argument are specified a list of all keys and their values are shown.
  LONGDESC
  arg "KEY", :optional
  arg "VALUE", :optional
  command "config" do |c|
    c.action do |global_options,options,args|
      key = args[0]
      value = args[1]

      task = ConfigTask.new
      task.config(key, value)

      if key == "hints" && !Machinery::Config.new.hints
        Machinery::Ui.puts "Hints can be switched on again by '#{$0} config hints on'."
      end
    end
  end
end
