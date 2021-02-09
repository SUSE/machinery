# frozen_string_literal: true

# Copyright (c) 2020 SUSE LLC
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

module Machinery
  # TODO(gyee): add .repositories
  # NOTE(gyee): the order matters
  SALT_INIT_SLS = %(include:
  - .groups
  - .users
  - .unmanaged_files
  - .packages
  - .managed_files
  - .services)

  class SaltStates < Machinery::Exporter
    attr_accessor :name

    def initialize(system_description, options = {})
      @name = "salt"
      @system_description = system_description
      @options = options

      @system_description.assert_scopes(
        "repositories",
        "packages",
        "os"
      )
      check_existance_of_extracted_files
      check_repositories
    end

    def write(output_location)
      File.write(File.join(output_location, "init.sls"), SALT_INIT_SLS)
      File.write(
        File.join(output_location, "repositories.sls"), repository_states
      )
      File.write(File.join(output_location, "packages.sls"), package_states)
      File.write(File.join(output_location, "groups.sls"), group_states)
      File.write(File.join(output_location, "users.sls"), user_states)
      File.write(File.join(output_location, "group_members.sls"),
                 group_members_states)
      File.write(File.join(output_location, "unmanaged_files.sls"),
                 unmanaged_file_states(output_location))
      File.write(File.join(output_location, "managed_files.sls"),
                 managed_file_states(output_location))
      File.write(File.join(output_location, "services.sls"), service_states)

      FileUtils.chmod 0o755, output_location
      FileUtils.chmod 0o755, Dir.glob("#{output_location}/**/*")
    end

    def export_name
      # NOTE(gyee): don't use system description name, which in most, if not
      # all cases, is the FQDN of the host. Salt does not allow dots (.) in
      # the export directory (config dir) name. Therefore, it's best to just
      # hash the name. The hash will keep it unique.
      hexname = Digest::SHA256.hexdigest @system_description.name
      @options.fetch("export-name", hexname)
    end

    private

    def check_existance_of_extracted_files
      missing_scopes = []
      [
        "changed_config_files",
        "changed_managed_files",
        "unmanaged_files"
      ].each do |scope|
        if @system_description[scope] &&
            !@system_description.scope_file_store(scope).path
          missing_scopes << scope
        end
      end

      unless missing_scopes.empty?
        raise Machinery::Errors::MissingExtractedFiles,
              @system_description, missing_scopes
      end
    end

    def check_repositories
      if @system_description.repositories.empty?
        raise Machinery::Errors::MissingRequirement,
              "The scope 'repositories' of the system description doesn't " \
              "contain a repository. " \
              "Please make sure that there is at least one accessible " \
              "repository with all the required packages."
      end
    end

    def add_group(name, gid)
      <<~SALT
        add-group-#{name}:
          group.present:
            - name: #{name}
            - gid: #{gid}

      SALT
    end

    # TODO(gyee): we have multiple issues to resolve:
    #
    # 1. it doesn't appear salt.states.group support group password facility.
    #    Do we care about supporting it?
    # 2. salt.states.group have a flag to designate a group as "system group".
    #    But Machinery doesn't appeared to harvest that information. Do we
    #    care about setting this flag?
    # 3. what happen if the given group already exist but contain a different
    #    set of members? Do we just add the new members or do we want to replace
    #    existing group members? For new, I've elected to replace existing
    #    group members so the target host is more consistent with the source
    #    host. We may need to revisit this decision later.
    # 4. right now we do not generate the Salt states for system groups (i.e.
    #    group with GID below 1000). Those are expected to be created by the
    #    packages with a pre-determined GID. Is this the right assumption? We
    #    if we run into a situation where a system group is manually created
    #    the system admin?
    def group_states
      groups_sls = ""
      @system_description.groups.each do |group|
        # FIXME(gyee): filter out the system groups as those are expected to be
        # created by the packages and their GIDs are pre-choosen. Per Linux
        # convention, any GID below 1000 is considered *system group*. If this
        # assumption is no longer valid, we'll need to make the filter
        # configurable.
        next unless group.gid >= 1000

        groups_sls += add_group(group.name, group.gid)
        # FIXME(gyee): adding group members via users states to avoid
        # circular dependency for now. May need to remove the commented out
        # code below later.
        # groups_sls += "    - members:\n" if not group.users.empty?
        # group.users.each do |member|
        #  groups_sls += "      - #{member}\n"
        # end
      end
      groups_sls
    end

    def add_group_member(name, gid, members)
      group_members = <<~SALT
        add-members-for-#{name}:
          group.present:
            - name: #{name}
            - gid: #{gid}
            - members:
      SALT
      group_members + members.map { |member| "      - #{member}" }.join("\n")
    end

    # NOTE(gyee): to prevent circular dependency, we'll first need to add the
    # groups, then modify the groups to add members once the members are created.
    def group_members_states
      group_members_sls = ""
      @system_description.groups.each do |group|
        next unless group.gid >= 1000
        next if group.users.empty?

        group_members_sls += add_group_member(
          group.name, group.gid, group.users
        )
        group_members_sls += "\n"
      end
      group_members_sls
    end

    def get_group_membership(user)
      groups = []
      @system_description.groups.each do |group|
        next unless group.gid >= 1000

        group.users.each do |member|
          if member == user
            groups.append(group.name)
            break
          end
        end
      end
      groups
    end

    def add_user(user, groups)
      user = <<~SALT
        add-user-#{user.name}:
          user.present:
            - fullname: #{user.comment}
            - name: #{user.name}
            - uid: #{user.uid}
            - gid: #{user.gid}
            - home: #{user.home}
            - shell: #{user.shell}
            - password: '#{user.encrypted_password}'
            - mindays: #{user.min_days}
            - maxdays: #{user.max_days}
            - maxdays: #{user.max_days}
            - warndays: #{user.warn_days}
            - inactdays: #{user.disable_days}
            - expire: #{user.disable_date}
      SALT
      if groups.empty?
        user
      else
        user + groups.map { |group| "    - #{group}" }.join("\n")
      end
    end

    def user_states
      users_sls = ""
      @system_description.users.each do |user|
        # FIXME(gyee): filter out the system users as those are expected to be
        # created by the packages and their UIDs are pre-choosen. Per Linux
        # convention, any UID below 1000 is considered *system user*. If this
        # assumption is no longer valid, we'll need to make the filter
        # configurable.
        next unless user.uid >= 1000

        groups = get_group_membership(user.name)

        users_sls += add_user(user, groups)
      end
      users_sls
    end

    def unmanaged_file_exclude_filter_options
      export_filters_file = File.join(
        Machinery::ROOT, "export_helpers/unmanaged_files_#{@name}_excludes"
      )
      exclude_files = File.readlines(export_filters_file).map(&:strip)

      if exclude_files.empty?
        ""
      else
        "--exclude #{exclude_files.join(" --exclude ")}"
      end
    end

    def add_unmanaged_file(filepath, filter_options)
      options = if filter_options.empty?
        ""
      else
        "    - options: #{filter_options}\n"
      end
      <<~SALT
        extract-archive-#{filepath}:
          archive.extracted:
            - name: /
            - source: salt://#{export_name}/#{filepath}
        #{options}
      SALT
    end

    # NOTE(gyee): tarballs_dir is relative to the /srv/salt/, where the Salt
    # state files are located.
    def unmanaged_file_states(output_location)
      salt_tarballs_dir = "unmanaged_files_tarballs"
      export_dir = File.join(output_location, salt_tarballs_dir)
      FileUtils.mkdir_p(export_dir, mode: 0o1777)
      filter_options = unmanaged_file_exclude_filter_options

      unmanaged_files_sls = ""
      if @system_description.scope_extracted?("unmanaged_files")
        # TODO(gyee): do we need to support filters?
        @system_description.unmanaged_files.export_files_as_tarballs(export_dir)
        Dir["#{export_dir}/**/*.tgz"].sort.each do |path|
          filepath = salt_tarballs_dir + path.gsub(export_dir, "")
          unmanaged_files_sls += add_unmanaged_file(filepath, filter_options)
        end
      end
      unmanaged_files_sls
    end

    def managed_file_scope_filter(scope)
      scope_excludes_file = "export_helpers/#{scope}_#{@name}_excludes"
      scope_filter = Machinery::Filter.new
      scope_path = "/#{scope}/name"
      if File.exist?(scope_excludes_file)
        File.readlines(scope_excludes_file).map(&:strip).each do |patterns|
          next if patterns.empty?

          definition = "#{scope_path}=#{patterns}"
          scope_filter.add_element_filter_from_definition(definition)
        end
      end
      scope_filter
    end

    def add_managed_deleted_file(file)
      <<~SALT
        delete-file-#{file.name}:
          file.absent:
            - name: #{file.name}

      SALT
    end

    def add_managed_directory(file)
      <<~SALT
        create-directory-#{file.name}:
          file.directory:
            - name: #{file.name}
            - user: #{file.user}
            - group: #{file.group}
            - dir_mode: #{file.mode}
            - recurse:
              - user
              - group
              - mode

      SALT
    end

    def add_managed_file(file, export_name)
      <<~SALT
        create-file-#{file.name}:
          file.managed:
            - name: #{file.name}
            - source: salt://#{export_name}/root#{file.name}
            - user: #{file.user}
            - group: #{file.group}
            - mode: #{file.mode}
            - makedirs: true

      SALT
    end

    def add_managed_link(file)
      <<~SALT
        create-link-#{file.name}:
          file.symlink:
            - name: #{file.name}
            - target: #{file.target}
            - user: #{file.user}
            - group: #{file.group}
            - mode: #{file.mode}
            - makedirs: true

      SALT
    end

    def managed_file_states(output_location)
      salt_root_dir = "root"
      output_root_path = File.join(output_location, salt_root_dir)
      FileUtils.mkdir_p(output_root_path)

      managed_files_sls = ""
      ["changed_managed_files", "changed_config_files"].each do |scope|
        next unless @system_description.scope_extracted?(scope)

        scope_path = "/#{scope}/name"
        scope_filter = managed_file_scope_filter(scope)
        @system_description[scope].each do |file|
          next if scope_filter.matches?(scope_path, file.name)

          if file.deleted?
            managed_files_sls += add_managed_deleted_file(file)
          elsif file.directory?
            managed_files_sls += add_managed_directory(file)
          elsif file.file?
            @system_description[scope].write_file(file, output_root_path)
            managed_files_sls += add_managed_file(file, export_name)
          elsif file.link?
            managed_files_sls += add_managed_link(file)
          end
        end
      end
      managed_files_sls
    end

    def add_package(package)
      <<~SALT
        install-package-#{package.name}:
          pkg.installed:
            - name: #{package.name}
            - version: '#{package.version}'

      SALT
    end

    def add_pattern(pattern)
      <<~SALT
        install-pattern-#{pattern.name}:
          pkg.installed:
            - name: pattern:#{pattern.name}
            - version: '#{pattern.version}'
            - includes: [pattern]

      SALT
    end

    def package_states
      uniq_packages = []
      packages_sls = ""
      @system_description&.packages&.each do |package|
        # FIXME(gyee): seem like a bug in inspection that it has duplicate
        # entries for packages in manifest.json.
        next if uniq_packages.include? package.name

        uniq_packages.push(package.name)
        packages_sls += add_package(package)
      end
      uniq_patterns = []
      @system_description&.patterns&.each do |pattern|
        # FIXME(gyee): seem like a bug in inspection that it has duplicate
        # entries for packages in manifest.json.
        next if uniq_patterns.include? pattern.name

        uniq_patterns.push(pattern.name)
        packages_sls += add_pattern(pattern)
      end
      packages_sls
    end

    def add_repo(repo)
      <<~SALT
        add-repository-#{repo.alias.tr(" ", "-")}
          pkgrepo.managed
            - name: #{repo.name}
            - baseurl: #{repo.url}
            - priority: #{repo.priority}
            - enabled: #{repo.enabled}
            - humanname: #{repo.alias}
            - refresh: #{repo.autorefresh}
            - gpgcheck: #{repo.gpgcheck}

      SALT
    end

    # TODO(gyee): we have multiple issues to resolve:
    #
    #  1. Currently salt.states does not support 'repo-type' (i.e. rpm-md). Do
    #     we care about repo-type? If so, we'll need to fix salt states or add
    #     the repos via shell script instead. This will increase complexity as
    #     zypper is also not idempotent.
    #  2. Do we need to filter out the none network accessible repos? i.e.
    #     media mounts which may not be available at the target VM.
    #  3. Do we need to filter out the disabled repos?
    def repository_states
      repos_sls = ""
      @system_description&.repositories&.each do |repo|
        repos_sls += add_repo(repo)
      end
      repos_sls
    end

    def add_service(state, service, enable)
      enable_service = enable ? "    - enable: True\n" : ""
      <<~SALT
        #{state}-#{service.name}:
          service.#{state}:
            - name: #{service.name}
        #{enable_service}
      SALT
    end

    def service_states
      services_sls = ""
      if @system_description.services
        uniq_services = []
        @system_description.services.each do |service|
          # FIXME(gyee): seem like a bug in inspection that it has duplicate
          # entries for services in manifest.json.
          next if uniq_services.include? service.name

          uniq_services.push(service.name)

          case service.state
          when "enabled"
            # FIXME(gyee): does 'enabled' also implies 'running'? Right now
            # inspection does not differentiate between enabled and started
            # versus enabled and not started. For now, lets assuming enabled
            # also implies started/running.
            services_sls += add_service("running", service, true)
          when "disabled", "masked", "unmasked"
            # TODO(gyee): what to do with "linked", "indirect", and "static"?
            services_sls += add_service(service.state, service, false)
          else
            Machinery::Ui.warn(
              "Warning: service state #{service.state} is not supported by " \
              "salt states."
            )
          end
        end
      end
      services_sls
    end
  end
end
