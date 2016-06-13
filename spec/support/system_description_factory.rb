# Copyright (c) 2013-2016 SUSE LLC
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

# SystemDescriptionFactory provides factory methods to easily create test
# system descriptions in a temporary environment
module SystemDescriptionFactory
  def self.included(klass)
    klass.extend(self)
  end

  def initialize_system_description_factory_store
    include GivenFilesystemSpecHelpers
    use_given_filesystem
  end

  def system_description_factory_store
    unless self.class < GivenFilesystemSpecHelpers
      raise RuntimeError.new("Call 'initialize_system_description_factory_store'" \
        " before trying to access the factory store.")
    end

    @store ||= SystemDescriptionStore.new(given_directory)
  end

  # Generates a system description in the temporary description store from raw
  # JSON. It does not try to parse the JSON into a SystemDescription object, so
  # this can be used to store descriptions with an old format version, for
  # example.
  def store_raw_description(name, json)
    Dir.mkdir(File.join(system_description_factory_store.base_path, name))
    File.write(File.join(system_description_factory_store.base_path, name, "manifest.json"), json)
  end

  # Creates a SystemDescription object. The description and how it is stored can
  # be configured via the options hash.
  #
  # Available options:
  # +name+: The name of the system description. Default: 'description'.
  # +store+: The SystemDescriptionStore where the description should be stored.
  #   Default: The temporary factory description store.
  # +store_on_disk+: If true, the description will be stored in the temporary
  #   description store. If false, the description is only created in-memory.
  # +json+: If this option is given, the system description will be generated
  #   from it. Otherwise an empty description is created.
  # +scopes+: The list of scopes to include in the generated system description
  # +extracted_scopes+: The list of extractable scopes that should be extracted.
  # +modified+: Modified date of the system description scopes.
  # +hostname+: Hostname of the inspected host.
  # +add_scope_meta+: Add meta data for each scope if true.
  # +filters+: Add filter information to the meta section
  # +format_version+: Define the format version for the system description
  def create_test_description(options = {})
    options = {
        name: "description",
        store_on_disk: false,
        scopes: [],
        extracted_scopes: [],
        modified: DateTime.now,
        hostname: "example.com",
        add_scope_meta: true
    }.merge(options)

    name  = options[:name] || "description"

    if options[:store_on_disk] && !options[:store]
      store = system_description_factory_store
    else
      store = options[:store] || SystemDescriptionMemoryStore.new
    end

    if options[:json]
      manifest = Manifest.new(name, options[:json])
      manifest.validate!
      description = SystemDescription.from_hash(name, store, manifest.to_hash)
    else
      description = build_description(name, store, options)
    end

    description.save if options[:store_on_disk]

    description
  end

  def create_test_description_json(options = {})
    options = {
      scopes: [],
      extracted_scopes: [],
      modified: DateTime.now,
      hostname: "example.com",
      add_scope_meta: true
    }.merge(options)

    json_objects = []
    meta = {
      format_version: options.fetch(:format_version, SystemDescription::CURRENT_FORMAT_VERSION)
    }
    meta[:filters] = options[:filter_definitions] if options[:filter_definitions]

    (["environment"] + options[:scopes] + options[:extracted_scopes]).uniq.each do |example_scope|
      json_objects << EXAMPLE_SCOPES[example_scope]
      if options[:add_scope_meta]
        JSON.parse(finalize_json(EXAMPLE_SCOPES[example_scope])).each_key do |scope|
          meta[scope] = {
            modified: options[:modified],
            hostname: options[:hostname]
          }
        end
      end
    end

    json_objects << "\"meta\": #{JSON.pretty_generate(meta)}"
    finalize_json(json_objects.join(",\n"))
  end

  private

  def finalize_json(json)
    "{\n" + json + "\n}"
  end

  def build_description(name, store, options)
    json = create_test_description_json(options)
    manifest = Manifest.new(name, json)
    manifest.validate!
    description = SystemDescription.from_hash(name, store, manifest.to_hash)

    options[:extracted_scopes].each do |extracted_scope|
      JSON.parse(finalize_json(EXAMPLE_SCOPES[extracted_scope])).each_key do |scope|
        description[scope].extracted = true
        next unless options[:store_on_disk]

        file_store = description.scope_file_store(scope)
        file_store.create
        description[scope].scope_file_store = file_store

        if scope == "unmanaged_files"
          FileUtils.touch(File.join(file_store.path, "files.tgz"))
          FileUtils.mkdir_p(File.join(file_store.path, "trees", "etc"))
          FileUtils.touch(
            File.join(file_store.path, "trees", "etc", "tarball with spaces.tgz")
          )
        else
          description[scope].each do |file|
            next if !file.file? || file.deleted?

            file_name = File.join(file_store.path, file.name)
            FileUtils.mkdir_p(File.dirname(file_name))
            File.write(file_name, "Stub data for #{file.name}.")
          end
        end
      end
    end

    description
  end

  EXAMPLE_SCOPES = {}

  EXAMPLE_SCOPES["environment"] = <<-EOF.chomp
    "environment": {
      "locale": "C"
    }
  EOF
  EXAMPLE_SCOPES["docker_environment"] = <<-EOF.chomp
    "environment": {
      "locale": "C",
      "system_type": "docker"
    }
  EOF
  EXAMPLE_SCOPES["empty_changed_managed_files"] = <<-EOF.chomp
    "changed_managed_files": {
      "_attributes": {
        "extracted": false
      },
      "_elements": []
    }
  EOF
  EXAMPLE_SCOPES["changed_managed_files"] = <<-EOF.chomp
    "changed_managed_files": {
      "_attributes": {
        "extracted": false
      },
      "_elements": [
        {
          "name": "/etc/deleted changed managed",
          "package_name": "mdadm",
          "package_version": "3.3",
          "status": "changed",
          "changes": ["deleted"]
        },
        {
          "name": "/usr/bin/replaced_by_link",
          "package_name": "mdadm",
          "package_version": "3.3",
          "status": "changed",
          "changes": ["link_path"],
          "type": "link",
          "target": "/tmp/foo",
          "user": "root",
          "group": "target",
          "mode": "777"
        },
        {
          "name": "/etc/cron.daily/cleanup",
          "package_name": "mdadm",
          "package_version": "3.3",
          "status": "changed",
          "changes": ["md5"],
          "user": "user",
          "group": "group",
          "mode": "644",
          "type": "file"
        },
        {
          "name": "/etc/cron.daily/logrotate",
          "package_name": "mdadm",
          "package_version": "3.3",
          "status": "changed",
          "changes": ["md5", "size"],
          "user": "user",
          "group": "group",
          "mode": "644",
          "type": "file"
        },
        {
          "name": "/etc/cron.d",
          "package_name": "mdadm",
          "package_version": "3.3",
          "status": "changed",
          "changes": ["group"],
          "user": "user",
          "group": "group",
          "mode": "644",
          "type": "dir"
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["empty_changed_config_files"] = <<-EOF.chomp
    "changed_config_files": {
      "_attributes": {
        "extracted": false
      },
      "_elements": []
    }
  EOF
  EXAMPLE_SCOPES["changed_config_files"] = <<-EOF.chomp
    "changed_config_files": {
      "_attributes": {
        "extracted": false
      },
      "_elements": [
        {
          "name": "/etc/deleted config",
          "package_name": "mdadm",
          "package_version": "3.3",
          "status": "changed",
          "changes": ["deleted"]
        },
        {
          "name": "/etc/cron tab",
          "package_name": "cron",
          "package_version": "4.1",
          "status": "changed",
          "changes": ["md5"],
          "user": "root",
          "group": "root",
          "mode": "644",
          "type": "file"
        },
        {
          "name": "/etc/replaced_by_link",
          "package_name": "mdadm",
          "package_version": "3.3",
          "status": "changed",
          "changes": ["link_path"],
          "type": "link",
          "target": "/tmp/foo",
          "user": "root",
          "group": "target",
          "mode": "777"
        },
        {
          "name": "/etc/somedir",
          "package_name": "mdadm",
          "package_version": "3.3",
          "status": "changed",
          "changes": ["group"],
          "user": "user",
          "group": "group",
          "mode": "755",
          "type": "dir"
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["groups"] = <<-EOF.chomp
    "groups": {
      "_elements": [
        {
          "name": "audio",
          "password": "x",
          "users": [
            "tux",
            "foo"
          ],
          "gid": 17
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["os"] = <<-EOF.chomp
    "os": {
      "name": "openSUSE 13.1 (Bottle)",
      "version": "13.1 (Bottle)",
      "architecture": "x86_64"
    }
  EOF
  EXAMPLE_SCOPES["os_sles12"] = <<-EOF.chomp
    "os": {
      "name": "SUSE Linux Enterprise Server 12",
      "version": "12",
      "architecture": "x86_64"
    }
  EOF
  EXAMPLE_SCOPES["os_sles11"] = <<-EOF.chomp
    "os": {
      "name": "SUSE Linux Enterprise Server 11",
      "version": "11 SP3",
      "architecture": "x86_64"
    }
  EOF
  EXAMPLE_SCOPES["empty_packages"] = <<-EOF.chomp
    "packages": {
      "_attributes": {
        "package_system": "rpm"
      },
      "_elements": []
    }
  EOF
  EXAMPLE_SCOPES["packages"] = <<-EOF.chomp
    "packages": {
      "_attributes": {
        "package_system": "rpm"
      },
      "_elements": [
        {
          "name": "bash",
          "version": "4.2",
          "release": "68.1.5",
          "arch": "x86_64",
          "vendor": "openSUSE",
          "checksum": "533e40ba8a5551204b528c047e45c169"
        },
        {
          "name": "openSUSE-release-dvd",
          "version": "13.1",
          "release": "1.10",
          "arch": "x86_64",
          "vendor": "SUSE LINUX Products GmbH, Nuernberg, Germany",
          "checksum": "2a3d5b29179daa1e65e391d0a0c1442d"
        },
        {
          "name": "autofs",
          "version": "5.0.9",
          "release": "3.6",
          "arch": "x86_64",
          "vendor": "Packman",
          "checksum": "6d5d012b0e8d33cf93e216dfab6b174e"
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["packages2"] = <<-EOF.chomp
    "packages": {
      "_attributes": {
        "package_system": "rpm"
      },
      "_elements": [
        {
          "name": "bash",
          "version": "4.3",
          "release": "68.1.5",
          "arch": "x86_64",
          "vendor": "openSUSE",
          "checksum": "533e40ba8a5551204b528c047e45c169"
        },
        {
          "name": "kernel-desktop",
          "version": "3.7.10",
          "release": "1.0",
          "arch": "i586",
          "vendor": "openSUSE",
          "checksum": "4a87f6b9ceae5d40a411fe52d0f17050"
        },
        {
          "name": "autofs",
          "version": "5.0.9",
          "release": "3.6",
          "arch": "x86_64",
          "vendor": "Packman",
          "checksum": "6d5d012b0e8d33cf93e216dfab6b174e"
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["dpkg_packages"] = <<-EOF.chomp
    "packages": {
      "_attributes": {
        "package_system": "dpkg"
      },
      "_elements": [
        {
          "name": "zlib1g:amd64",
          "version": "1:1.2.8.dfsg",
          "release": "1ubuntu1",
          "arch": "amd64",
          "checksum": "468af3913970b3264a2525959e37a871",
          "vendor": "Ubuntu"
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["package_without_vendor"] = <<-EOF.chomp
    "packages": {
      "_attributes": {
        "package_system": "rpm"
      },
      "_elements": [
        {
          "name": "bash",
          "version": "4.3",
          "release": "68.1.5",
          "arch": "x86_64",
          "vendor": "",
          "checksum": "533e40ba8a5551204b528c047e45c169"
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["empty_patterns"] = <<-EOF.chomp
    "patterns": {
      "_elements": []
    }
  EOF
  EXAMPLE_SCOPES["patterns"] = <<-EOF.chomp
    "patterns": {
      "_attributes" :
        {
          "patterns_system": "zypper"
        },
      "_elements": [
        {
          "name": "base",
          "version": "13.1",
          "release": "13.6.1"
        },
        {
          "name": "Minimal",
          "version": "11",
          "release": "38.44.33"
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["patterns_with_dpkg"] = <<-EOF.chomp
    "patterns": {
      "_attributes" :
        {
          "patterns_system": "tasksel"
        },
      "_elements": [
        {
          "name": "base"
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["empty_repositories"] = <<-EOF.chomp
    "repositories": {
      "_attributes": {
        "repository_system": "zypp"
      },
      "_elements": []
    }
  EOF
  EXAMPLE_SCOPES["apt_repositories"] = <<-EOF.chomp
    "repositories": {
      "_attributes": {
        "repository_system": "apt"
      },
      "_elements": [
        {
          "url": "http://de.archive.ubuntu.com/ubuntu/",
          "type": "deb",
          "distribution": "trusty",
          "components": [
            "main",
            "restricted"
          ]
        },
        {
          "url": "http://de.archive.ubuntu.com/ubuntu/",
          "type": "deb-src",
          "distribution": "trusty",
          "components": [
            "main",
            "restricted"
          ]
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["zypp_repositories"] = <<-EOF.chomp
    "repositories": {
      "_attributes": {
        "repository_system": "zypp"
      },
      "_elements": [
        {
          "alias": "nodejs_alias",
          "name": "nodejs",
          "type": "rpm-md",
          "url": "http://download.opensuse.org/repositories/devel:/languages:/nodejs/openSUSE_13.1/",
          "enabled": true,
          "autorefresh": false,
          "gpgcheck": true,
          "priority": 1
        },
        {
          "alias": "openSUSE-13.1-1.7_alias",
          "name": "openSUSE-13.1-1.7",
          "type": "rpm-md",
          "url": "cd:///?devices=/dev/disk/by-id/ata-Optiarc_DVD+_-RW_AD-7200S,/dev/sr0",
          "enabled": false,
          "autorefresh": false,
          "gpgcheck": true,
          "priority": 2
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["repositories"] = <<-EOF.chomp
    "repositories": {
      "_attributes": {
        "repository_system": "zypp"
      },
      "_elements": [
        {
          "alias": "nodejs_alias",
          "name": "nodejs",
          "type": "rpm-md",
          "url": "http://download.opensuse.org/repositories/devel:/languages:/nodejs/openSUSE_13.1/",
          "enabled": true,
          "autorefresh": false,
          "gpgcheck": true,
          "priority": 1
        },
        {
          "alias": "openSUSE-13.1-1.7_alias",
          "name": "openSUSE-13.1-1.7",
          "type": "yast2",
          "url": "cd:///?devices=/dev/disk/by-id/ata-Optiarc_DVD+_-RW_AD-7200S,/dev/sr0",
          "enabled": false,
          "autorefresh": false,
          "gpgcheck": true,
          "priority": 2
        },
        {
          "alias": "repo_without_type_alias",
          "name": "repo_without_type",
          "type": null,
          "url": "http://repo-without-type",
          "enabled": true,
          "autorefresh": false,
          "gpgcheck": true,
          "priority": 3
        },
        {
          "alias": "disabled_repo_alias",
          "name": "disabled_repo",
          "type": null,
          "url": "http://disabled-repo",
          "enabled": false,
          "autorefresh": false,
          "gpgcheck": true,
          "priority": 3
        },
        {
          "alias": "autorefresh_enabled_alias",
          "name": "autorefresh_enabled",
          "type": null,
          "url": "http://autorefreshed-repo",
          "enabled": true,
          "autorefresh": true,
          "gpgcheck": true,
          "priority": 2
        },
        {
          "alias": "dvd_entry_alias",
          "name": "dvd_entry",
          "type": "yast2",
          "url": "dvd:///?devices=/dev/disk/by-id/ata-Optiarc_DVD+_-RW_AD-7200S,/dev/sr0",
          "enabled": true,
          "autorefresh": false,
          "gpgcheck": true,
          "priority": 2
        },
        {
          "alias": "NCCRepo",
          "name": "NCC Repository",
          "type": "yast2",
          "url": "https://nu.novell.com/repo/$RCE/SLES11-SP3-Pool/sle-11-x86_64?credentials=NCCcredentials",
          "enabled": true,
          "autorefresh": true,
          "gpgcheck": true,
          "priority": 2
        },
        {
          "alias": "Alias With Spaces",
          "name": "nodejs",
          "type": "rpm-md",
          "url": "http://download.opensuse.org/repositories/devel:/languages:/nodejs/openSUSE_13.1/",
          "enabled": true,
          "autorefresh": false,
          "gpgcheck": true,
          "priority": 1
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["yum_repositories"] = <<-EOF.chomp
    "repositories": {
      "_attributes": {
        "repository_system": "yum"
      },
      "_elements": [
        {
          "name": "CentOS-6Server - Base",
          "url": [
            "http://mirror.centos.org/centos/centos4/os/x86_64/",
            "http://mirror2.centos.org/centos/centos4/os/x86_64/"
          ],
          "gpgkey": [
            "http://mirror.centos.org/centos/RPM-GPG-KEY-centos4",
            "http://mirror2.centos.org/centos/RPM-GPG-KEY-centos4"
          ],
          "enabled": true,
          "alias": "base",
          "mirrorlist": "",
          "gpgcheck": true,
          "type": "rpm-md"
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["users"] = <<-EOF.chomp
    "users": {
      "_attributes": {},
      "_elements": [
        {
          "name": "bin",
          "password": "x",
          "uid": 1,
          "gid": 1,
          "comment": "bin",
          "home": "/bin",
          "shell": "/bin/bash",
          "encrypted_password": "*",
          "last_changed_date": 16125
        }
      ]
    }
  EOF

  EXAMPLE_SCOPES["users_without_comment"] = <<-EOF.chomp
    "users": {
      "_attributes": {},
      "_elements": [
        {
          "name": "bin",
          "password": "x",
          "uid": null,
          "gid": 1,
          "comment": "",
          "home": "/bin",
          "shell": "/bin/bash",
          "encrypted_password": "*",
          "last_changed_date": 16125
        }
      ]
    }
  EOF

  EXAMPLE_SCOPES["users_with_passwords"] = <<-EOF.chomp
    "users": {
      "_elements": [
        {
          "name": "root",
          "password": "x",
          "uid": 0,
          "gid": 0,
          "comment": "root",
          "home": "/root",
          "shell": "/bin/bash",
          "encrypted_password": "$6$E4YLEez0s3MP$YkWtqN9J8uxEsYgv4WKDLRKxM2aNCSJajXlffV4XGlALrHzfHg1XRVxMht9XBQURDMY8J7dNVEpMaogqXIkL0.",
          "last_changed_date": 16357
        },
        {
          "name": "vagrant",
          "password": "x",
          "uid": 1000,
          "gid": 100,
          "comment": "",
          "home": "/home/vagrant",
          "shell": "/bin/bash",
          "encrypted_password": "$6$6V/YKqrsHpkC$nSAsvrbcVE8kTI9D3Z7ubc1L/dBHXj47BlL5usy0JNINzXFDl3YXqF5QYjZLTo99BopLC5bdHYUvkUSBRC3a3/",
          "last_changed_date": 16373,
          "min_days": 0,
          "max_days": 99999,
          "warn_days": 7,
          "disable_days": 30,
          "disabled_date": 1234
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["empty_services"] = <<-EOF.chomp
    "services": {
      "_attributes": {
        "init_system": "systemd"
      },
      "_elements": []
    }
  EOF
  EXAMPLE_SCOPES["docker_services"] = <<-EOF.chomp
    "services": {
      "_attributes": {
        "init_system": "none"
      },
      "_elements": [

      ]
    }
  EOF
  EXAMPLE_SCOPES["services"] = <<-EOF.chomp
    "services": {
      "_attributes": {
        "init_system": "systemd"
      },
      "_elements": [
        {
          "name": "sshd.service",
          "state": "enabled"
        },
        {
          "name": "rsyncd.service",
          "state": "disabled"
        },
        {
          "name": "lvm2-lvmetad.socket",
          "state": "disabled"
        },
        {
          "name": "console-shell.service",
          "state": "static"
        },
        {
          "name": "crypto.service",
          "state": "masked"
        },
        {
          "name": "static.service",
          "state": "static"
        },
        {
          "name": "linked.service",
          "state": "linked"
        },
        {
          "name": "enabled_runtime.service",
          "state": "enabled-runtime"
        },
        {
          "name": "linked_runtime.service",
          "state": "linked-runtime"
        },
        {
          "name": "masked_runtime.service",
          "state": "masked-runtime"
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["services_sysvinit"] = <<-EOF.chomp
    "services": {
      "_attributes": {
        "init_system": "sysvinit"
      },
      "_elements": [
        {
          "name": "sshd",
          "state": "on"
        },
        {
          "name": "rsyncd",
          "state": "off"
        }
      ]
    }
  EOF
  EXAMPLE_SCOPES["empty_unmanaged_files"] = <<-EOF.chomp
    "unmanaged_files": {
      "_attributes": {
        "extracted": false,
        "has_metadata": false
      },
      "_elements": []
    }
  EOF
  EXAMPLE_SCOPES["unmanaged_files"] = <<-EOF.chomp
    "unmanaged_files": {
      "_attributes": {
        "extracted": false,
        "has_metadata": true
      },
      "_elements": [
        {
          "name": "/etc/unmanaged-file",
          "type": "file",
          "user": "root",
          "group": "root",
          "size": 8,
          "mode": "644"
        },
        {
          "name": "/etc/another-unmanaged-file",
          "type": "file",
          "user": "root",
          "group": "root",
          "size": 8,
          "mode": "644"
        },
        {
          "name": "/etc/tarball with spaces/",
          "type": "dir",
          "user": "root",
          "group": "root",
          "size": 12345,
          "mode": "755",
          "files": 14,
          "dirs": 2
        }
      ]
    }
  EOF
end
