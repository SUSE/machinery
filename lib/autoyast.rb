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

class Autoyast
  def initialize(description)
    @system_description = description
    @system_description.assert_scopes(
      "repositories",
      "packages"
    )
  end

  def write(output_dir)
    FileUtils.cp(
      File.join(Machinery::ROOT, "export_helpers/unmanaged_files_build_excludes"),
      output_dir
    )
    # Filter log files to prevent an issue with hanging gzip during installation
    File.open(File.join(output_dir, "unmanaged_files_build_excludes"), "a") do |file|
      file.puts "var/log/*"
    end
    FileUtils.chmod(0600, File.join(output_dir, "unmanaged_files_build_excludes"))
    FileUtils.cp(
      File.join(Machinery::ROOT, "export_helpers/autoyast_export_readme.md"),
      File.join(output_dir, "README.md")
    )
    Dir["#{@system_description.description_path}/*"].each do |content|
      FileUtils.cp_r(content, output_dir, preserve: true)
    end
    File.write(File.join(output_dir, "autoinst.xml"), profile)
    FileUtils.chmod(0600, File.join(output_dir, "autoinst.xml"))
    Machinery::Ui.puts(
      "Note: The permssions of the AutoYaST directory are restricted to be" \
        " only accessible by the current user. Further instructions are" \
        " provided by the README.md in the exported directory."
    )
  end

  def profile
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.doc.create_internal_subset("profile", nil, nil)
      xml.profile(
        "xmlns" => "http://www.suse.com/1.0/yast2ns",
        "xmlns:config" => "http://www.suse.com/1.0/configns"
      ) do
        setup_basic_network(xml)
        apply_repositories(xml)
        xml.software do
          apply_packages(xml)
          apply_patterns(xml)
        end
        apply_users(xml)
        apply_groups(xml)
        apply_services(xml)

        chroot_scripts = []
        chroot_scripts << extracted_files_script("config_files")
        chroot_scripts << extracted_files_script("changed_managed_files")
        chroot_scripts << unmanaged_files_script
        xml.scripts do
          apply_url_extraction(xml)
          xml.send("chroot-scripts", "config:type" => "list") do
            xml.script do
              xml.source do
                xml.cdata chroot_scripts.join("\n")
              end
            end
          end
        end
      end
    end

    builder.to_xml
  end

  private

  def setup_basic_network(xml)
    xml.networking do
      xml.keep_install_network "true", "config:type" => "boolean"
    end
  end

  def apply_repositories(xml)
    return if !@system_description.repositories

    xml.send("add-on") do
      xml.add_on_products("config:type" => "list") do
        @system_description.repositories.each do |repository|
          xml.listentry do
            xml.media_url repository.url
            xml.name repository.alias
          end
        end
      end
    end
  end

  def apply_packages(xml)
    return if !@system_description.packages

    xml.packages("config:type" => "list") do
      @system_description.packages.each do |package|
        xml.package package.name
      end
    end
  end

  def apply_patterns(xml)
    return if !@system_description.patterns

    xml.patterns("config:type" => "list") do
      @system_description.patterns.each do |pattern|
        xml.pattern pattern.name
      end
    end
  end

  def apply_users(xml)
    return if !@system_description.users

    xml.users("config:type" => "list") do
      @system_description.users.each do |user|
        xml.user do
          xml.username user.name
          xml.user_password user.encrypted_password
          xml.encrypted "true", "config:type" => "boolean"
          xml.uid user.uid
          xml.gid user.gid
          xml.home user.home
          xml.shell user.shell
          xml.fullname user.comment
          xml.password_settings do
            xml.min user.min_days
            xml.max user.max_days
            xml.warn user.warn_days
            xml.inact user.disable_days
            xml.expire user.disabled_date
          end
        end
      end
    end
  end

  def apply_groups(xml)
    return if !@system_description.groups

    xml.groups("config:type" => "list") do
      @system_description.groups.each do |group|
        xml.group do
          xml.encrypted "true", "config:type" => "boolean"
          xml.gid group.gid
          xml.groupname group.name
          xml.group_password group.password
          xml.userlist group.users.join(",")
        end
      end
    end
  end

  def apply_services(xml)
    return if !@system_description.services

    xml.send("services-manager") do
      xml.services("config:type" => "list") do
        @system_description.services.services.each do |service|
          name = service.name
          if @system_description.services.init_system == "systemd"
            # Yast can only handle services right now
            next if !(name =~ /\.service$/)
            name = name.gsub(/\.service$/, "")
          end
          # systemd service states like "masked" and "static" are
          # not supported by Autoyast
          if service.enabled?
            xml.service do
              xml.service_name name
              xml.service_status "enable"
            end
          end
          if service.disabled?
            xml.service do
              xml.service_name name
              xml.service_status "disable"
            end
          end
        end
      end
    end
  end

  def apply_url_extraction(xml)
    xml.send("pre-scripts", "config:type" => "list") do
      xml.script do
        xml.source do
          xml.cdata 'sed -n \'/.*autoyast2\?=\(.*\)\/.*[^\s]*/s//\1/p\'' \
            ' /proc/cmdline > /tmp/description_url'
        end
      end
    end
  end

  def extracted_files_script(scope)
    return if !@system_description[scope] || !@system_description[scope].extracted

    base = Pathname(@system_description.file_store(scope))
    snippets = []
    Dir["#{base}/**/*"].sort.each do |path|
      next if File.directory?(path)

      relative_path = Pathname(path).relative_path_from(base).to_s
      url = "`cat /tmp/description_url`/#{URI.escape(File.join(scope, relative_path))}"

      snippets << "mkdir -p '#{File.join("/mnt", File.dirname(relative_path))}'"
      snippets << "curl -o '#{File.join("/mnt", relative_path)}' \"#{url}\""
    end

    @system_description[scope].files.map do |file|
      snippets << "chown #{file.user}:#{file.group} '#{File.join("/mnt", file.name)}'" if file.user
      snippets << "chmod #{file.mode} '#{File.join("/mnt", file.name)}'" if file.mode
    end

    snippets.join("\n")
  end

  def unmanaged_files_script
    return if !@system_description.unmanaged_files ||
      !@system_description.unmanaged_files.extracted

    base = Pathname(@system_description.file_store("unmanaged_files"))
    snippets = []
    snippets << <<-EOF
      curl -o '/mnt/tmp/filter' "`cat /tmp/description_url`/unmanaged_files_build_excludes"
    EOF

    Dir["#{base}/**/*.tgz"].sort.each do |path|
      next if !path.end_with?(".tgz")

      relative_path = Pathname(path).relative_path_from(base).to_s
      tarball_name = File.basename(path)
      url = "`cat /tmp/description_url`#{URI.escape(File.join("/unmanaged_files", relative_path))}"

      snippets << <<-EOF
        curl -o '/mnt/tmp/#{tarball_name}' "#{url}"
        tar -C /mnt/ -X '/mnt/tmp/filter' -xf '#{File.join("/mnt/tmp", tarball_name)}'
        rm '#{File.join("/mnt/tmp", tarball_name)}'
      EOF
    end

    snippets.join("\n")
  end
end
