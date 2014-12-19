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
  # By default it the RPM is built for openSUSE 13.1 with the configuration from
  # https://build.opensuse.org/project/show/systemsmanagement:machinery/machinery
  #
  # This can be overriden when provisioning a VM:
  #
  #   machinery_sles.vm.provision "machinery_rpm",
  #     :api     => "https://your.buildservice.com",
  #     :project => "machinery_project",
  #     :package => "machinery"
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
      cmd = "cd #{MACHINERY_ROOT} && export HOME=$(echo ~/) && " \
        "export LC_ALL=en_US.utf8 && SKIP_CLEANUP=true rake rpm:build#{obs_cmd} 2>&1"
      rpm_output = `env -i bash -lc "#{cmd}"`
      @rpm = Dir.entries(File.join(MACHINERY_ROOT, "package")).select do |file|
        file =~ /^machinery-\d.*\.x86_64\.rpm$/
      end.first

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

      cmd = "zypper --non-interactive in /tmp/#{@rpm}"
      machine.communicate.execute(cmd, sudo: true)
    end
  end

  class Config < Vagrant.plugin(2, :config)
    attr_accessor :api
    attr_accessor :project
    attr_accessor :package
  end
end
