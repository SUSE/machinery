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

module MachineryRpm
  # This vagrant plugin takes care of building a Machinery RPM from the local
  # source code and installing it in the VM.
  #
  # It can be enabled for specific VMs like this:
  #
  #   config.vm.define :machinery_131 do |machinery_131|
  #     ...
  #     machinery_131.vm.provision "machinery_rpm"
  #   end
  #
  # By default it the RPM is built with the configuration from
  # https://build.opensuse.org/project/show/systemsmanagement:machinery/machinery
  #
  # This can be overriden when provisioning a VM:
  #
  #   machinery_sles.vm.provision "machinery_rpm",
  #     api: "https://your.buildservice.com",
  #     project: "machinery_project",
  #     package: "machinery"
  #
  class Plugin < Vagrant.plugin('2')
    name "machinery_rpm"

    config "machinery_rpm", :provisioner do
      Config
    end

    provisioner "machinery_rpm" do
      Provisioner
    end
  end

  class Provisioner < Vagrant.plugin(2, :provisioner)
    MACHINERY_ROOT = File.expand_path("../../../../", __FILE__)

    def provision
      build
      upload
      install
    end

    private

    def build
      machine.ui.detail("Building Machinery RPM...")

      if config.api && config.project && config.package
        obs_cmd = "[#{config.api},#{config.project},#{config.package}]"
      else
        obs_cmd = ""
      end

      # Vagrantfile sets up its own environment which prevents rake from working
      # So we reset the environment and specify the only missing environment variable
      cmds = []
      cmds << "cd #{MACHINERY_ROOT}"
      cmds << "export HOME=$(echo ~/)"
      cmds << "export LC_ALL=en_US.utf8"
      # Forward SKIP_RPM_CLEANUP environment variable to the new, clean environment
      cmds << "export SKIP_RPM_CLEANUP=true" if ENV["SKIP_RPM_CLEANUP"] == "true"
      cmds << "rake rpm:build#{obs_cmd}"

      cmd = cmds.join(" && ") + " 2>&1"
      rpm_output = `env -i bash -lc "#{cmd}"`
      package_root = File.join(MACHINERY_ROOT, "package")
      @rpm = Dir.entries(package_root).
        sort_by { |f| File.stat(File.join(package_root, f)).mtime }.
        select do |file|
          file =~ /^machinery-\d.*\.x86_64\.rpm$/
        end.last

      if !$?.success? || !@rpm
        raise "Building the rpm package failed.\n#{rpm_output}"
      end
    end

    def upload
      machine.ui.detail("Uploading Machinery RPM...")

      machine.communicate.upload(File.join(MACHINERY_ROOT, "package", @rpm), "/tmp/#{@rpm}")
    end

    def install
      machine.ui.detail("Installing Machinery...")

      cmd = "zypper --no-gpg-checks --non-interactive in /tmp/#{@rpm}"
      machine.communicate.execute(cmd, sudo: true)
    end
  end

  class Config < Vagrant.plugin(2, :config)
    attr_accessor :api
    attr_accessor :project
    attr_accessor :package
  end
end
