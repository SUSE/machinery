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

class KiwiConfig
  attr_accessor :xml, :sh

  def initialize(system_description, options = {})
    @system_description = system_description
    @name = system_description.name
    @options = options

    @system_description.assert_scopes(
      "repositories",
      "packages",
      "os"
    )
    check_existance_of_extraced_files

    generate_config
  end

  def write(output_location)
    inject_users_and_groups(output_location)
    inject_extracted_files(output_location)

    @sh << "baseCleanMount\n"
    @sh << "exit 0\n"
    File.write(File.join(output_location, "config.xml") , @xml.to_xml)
    File.write(File.join(output_location, "config.sh") , @sh)
    FileUtils.cp(
       File.join(Machinery::ROOT, "kiwi_helpers/kiwi_export_readme.md"),
       File.join(output_location, "README.md")
    )

    post_process_config(output_location)
  end

  private

  def pre_process_config
    enable_ssh if @options[:enable_ssh]
  end

  def post_process_config(output_location)
    enable_dhcp(output_location) if @options[:enable_dhcp]
  end

  def inject_users_and_groups(output_location)
    return if !@system_description.users || !@system_description.groups

    merge_script_name = "merge_users_and_groups.pl"

    template = ERB.new(
      File.read(File.join(Machinery::ROOT, "kiwi_helpers", "#{merge_script_name}.erb"))
    )

    passwd_entries = @system_description.users.map do |u|
      passwd = [u.name, u.password, u.uid, u.gid, u.comment, u.home, u.shell].join(":")

      # The shadow file contains an eigth reserved field at the end, so we have
      # to manually add it, too.
      shadow = [u.name, u.encrypted_password, u.last_changed_date, u.min_days,
        u.max_days, u.warn_days, u.disable_days, u.disabled_date, ""].join(":")
      "['#{passwd}', '#{shadow}']"
    end.join(",\n")
    group_entries = @system_description.groups.map do |g|
      "'#{g.name}:#{g.password}:#{g.gid}:#{g.users.join(",")}'"
    end.join(",\n")

    FileUtils.mkdir_p(File.join(output_location, "root", "tmp"), mode: 01777)
    script_path = File.join(output_location, "root", "tmp", merge_script_name)
    File.write(script_path, template.result(binding))

    @sh << "perl /tmp/#{merge_script_name} /etc/passwd /etc/shadow /etc/group\n"
    @sh << "rm /tmp/#{merge_script_name}\n"
  end

  def inject_extracted_files(output_location)
    ["config_files", "changed_managed_files"].each do |dir|
      path = @system_description.file_store(dir)
      if path
        output_root_path = File.join(output_location, "root")
        FileUtils.mkdir_p(output_root_path)
        FileUtils.cp_r(Dir.glob("#{path}/*"), output_root_path)
      end
    end

    unmanaged_files_path = @system_description.file_store("unmanaged_files")
    if unmanaged_files_path
      filter = "unmanaged_files_build_excludes"
      destination = File.join(output_location, "root", "tmp")
      FileUtils.mkdir_p(destination, mode: 01777)
      FileUtils.cp_r(unmanaged_files_path, destination)
      FileUtils.cp(
        File.join(Machinery::ROOT, "kiwi_helpers/#{filter}"),
        destination
      )

      @sh << "# Apply the extracted unmanaged files\n"
      @sh << "find /tmp/unmanaged_files -name *.tgz -exec " \
        "tar -C / -X '/tmp/#{filter}' -xf {} \\;\n"
      @sh << "rm -rf '/tmp/unmanaged_files' '/tmp/#{filter}'\n"
    end
  end

  def check_existance_of_extraced_files
    scopes = []
    ["config_files", "changed_managed_files", "unmanaged_files"].each do |scope|
      path = @system_description.file_store(scope)

      if @system_description[scope] && !path
        scopes << scope
      end
    end

    if !scopes.empty?
      raise Machinery::Errors::SystemDescriptionError.new(
        "Cannot create kiwi config. " \
        "The following scopes #{Cli.internal_to_cli_scope_names(scopes).join(",")} " \
        "are part of the system description but the corresponding files " \
        "weren't extracted during inspection.\n" \
        "Use the -x parameter while running inspect to extract the files."
      )
    end
  end

  def generate_config
    @sh = <<EOF
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile
baseMount
suseSetupProduct
suseImportBuildKey
suseConfig
EOF
    case @system_description.os_object
      when OsSles12
        boot = "vmxboot/suse-SLES12"
        bootloader = "grub2"
      when OsSles11
        boot = "vmxboot/suse-SLES11"
        bootloader = "grub"
      else
        raise Machinery::Errors::KiwiExportFailed.new(
          "Building is not possible because the operating system " \
          "'#{@system_description.os_object.name}' is not supported."
        )
    end

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.image(schemaversion: "5.8", name: @system_description.name) do
        xml.description(type: "system") do
          xml.author "Machinery"
          xml.contact ""
          xml.specification "Description of system '#{@system_description.name}' exported by Machinery"
        end

        xml.preferences do
          xml.packagemanager "zypper"
          xml.version "0.0.1"
          xml.type_(image: "vmx", filesystem: "ext3", installiso: "true",
                   boot: boot, format: "qcow2", bootloader: bootloader)
        end

        xml.users(group: "root") do
          xml.user(password: "$1$wYJUgpM5$RXMMeASDc035eX.NbYWFl0",
            home: "/root", name: "root")
        end


        apply_repositories(xml)
        apply_packages(xml)
        apply_extracted_files_attributes
        apply_services
      end
    end

    pre_process_config

    @xml = builder.doc
  end

  def apply_packages(xml)
    xml.packages(type: "bootstrap") do
      if @system_description.packages
        @system_description.packages.each do |package|
          xml.package(name: "#{package.name}")
        end
      end
      pattern_array = Array.new
      if @system_description.patterns
        @system_description.patterns.each do |pattern|
          xml.namedCollection(name: "#{pattern.name}")
        end
      end
    end
  end

  def apply_repositories(xml)
    if @system_description.repositories
      @system_description.repositories.each do |repo|
        # only use accessible repositories as source for kiwi build
        parameters = { type: repo.type, priority: repo.priority }
        if repo.username && repo.password
          parameters[:username] = repo.username
          parameters[:password] = repo.password
        end
        is_external_medium = repo.url.start_with?("cd://") ||
          repo.url.start_with?("dvd://")
        if repo.enabled && !repo.type.nil? && !is_external_medium
          xml.repository(parameters) do
            xml.source(path: repo.url)
          end
        end
        if !repo.url.match(/^https:\/\/nu.novell.com|^https:\/\/update.suse.com/)
          @sh << "zypper -n ar --name='#{repo.name}' "
          @sh << "--type='#{repo.type}' " if repo.type
          @sh << "--refresh " if repo.autorefresh
          @sh << "--disable " unless repo.enabled
          @sh << "'#{repo.url}' '#{repo.alias}'\n"
          @sh << "zypper -n mr --priority=#{repo.priority} '#{repo.name}'\n"
        end
      end
    end
  end

  def apply_extracted_files_attributes
    ["config_files", "changed_managed_files"].each do |scope|
      if @system_description[scope]
        deleted, files = @system_description[scope].partition do |f|
          f.changes == Machinery::Array.new(["deleted"])
        end

        files.each do |file|
          @sh << "chmod #{file.mode} '#{file.name}'\n"
          @sh << "chown #{file.user}:#{file.group} '#{file.name}'\n"
        end

        deleted.each do |file|
          @sh << "rm -rf '#{file.name}'\n"
        end
      end
    end
  end

  def apply_services
    if @system_description["services"]
      init_system = @system_description["services"].init_system

      case init_system
        when "sysvinit"
          @system_description["services"].services.each do |service|
            if service.state == "on"
              @sh << "chkconfig #{service.name} on\n"
            else
              @sh << "chkconfig #{service.name} off\n"
            end
          end

        when "systemd"
          # possible systemd service states:
          # http://www.freedesktop.org/software/systemd/man/systemctl.html#Unit%20File%20Commands
          @system_description["services"].services.each do |service|
            case service.state
              when "enabled"
                @sh << "systemctl enable #{service.name}\n"
              when "disabled"
                @sh << "systemctl disable #{service.name}\n"
              when "masked"
                @sh << "systemctl mask #{service.name}\n"
              when "static"
                # Don't do anything because the unit is not meant to be
                # enabled/disabled manually.
              when "linked"
                # Don't do anything because linking doesn't mean enabling
                # nor disabling.
              when "enabled-runtime"
              when "linked-runtime"
              when "masked-runtime"
                # Don't do anything because these states are not supposed
                # to be permanent.
              else
                raise Machinery::Errors::KiwiExportFailed.new(
                  "The systemd unit state #{service.state} is unknown."
                )
            end
          end

        else
          raise "Unsupported init system: #{init_system.inspect}."
      end
    end
  end

  def enable_dhcp(output_location)
    case @system_description.os_object
      when OsSles11
        write_dhcp_network_config(output_location, "eth0")
      when OsSles12
        write_dhcp_network_config(output_location, "lan0")
        write_persistent_net_rules(output_location)
    end
    puts "DHCP in built image will be enabled for the first device"
  end

  def write_dhcp_network_config(output_location, device)
    network_location = File.join(output_location, "root/etc/sysconfig/network")
    FileUtils.mkdir_p(network_location)
    File.write(File.join(network_location, "ifcfg-#{device}"),
      "BOOTPROTO='dhcp'\nSTARTMODE='onboot'"
    )
  end

  def write_persistent_net_rules(output_location)
    udev_location = File.join(output_location, "root/etc/udev/rules.d")
    persistent_net_rule = [
      'SUBSYSTEM=="net"',
      'ACTION=="add"',
      'DRIVERS=="?*"',
      'ATTR{address}=="?*"',
      'ATTR{dev_id}=="0x0"',
      'ATTR{type}=="1"',
      'KERNEL=="?*"',
      'NAME="lan0"'
    ]

    FileUtils.mkdir_p(udev_location)
    File.write(
      File.join(udev_location, "70-persistent-net.rules"),
      persistent_net_rule.join(", ")
    )
  end

  def enable_ssh
    @sh << "suseInsertService sshd\n"
  end
end
