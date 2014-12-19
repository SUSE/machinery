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

# Zypper is a wrapper class around the zypper package manager
#
# Zypper offers access to the system-wide zypper environment, but it also allows
# for running zypper in an isolated environment using 'Zypper.isolated'.
# That way Machinery can safely add repositories and download packages without
# polluting the host.
class Zypper
  attr_accessor :zypper_options

  class <<self
    def isolated(options = {}, &block)
      zypper_base = Dir.mktmpdir("machinery_zypper")
      zypper = Zypper.new

      zypper.zypper_options = [
        "--non-interactive",
        "--no-gpg-checks",
        "--root", zypper_base
      ]

      if options[:arch]
        config = create_arch_config(zypper_base, options[:arch])
        zypper.zypper_options.unshift("--config", config)
      end

      block.call(zypper)
    ensure
      cleanup(zypper_base)
    end

    private

    def create_arch_config(base, arch)
      config = File.join(base, "zypp.conf")

      File.new(config, "w")
      File.write(config,
        "[main]\n" \
        "arch=#{arch}"
      )

      config
    end

    def cleanup(base)
      LoggedCheetah.run("sudo", "rm", "-r", base)
    end
  end

  def add_repo(url, repo_alias)
    call_zypper "ar", url, repo_alias
  end

  def remove_repo(repo_alias)
    call_zypper "rr", repo_alias
  end

  def refresh
    call_zypper "refresh"
  end

  def download_package(package)
    raw_xml = call_zypper "-x", "download", package, :stdout => :capture

    xml = Nokogiri::XML(raw_xml)
    xml.xpath("//localfile/@path").to_s
  end

  private

  def call_zypper(*args)
    cmd = ["sudo", "zypper"]
    cmd += @zypper_options if @zypper_options
    cmd += args

    LoggedCheetah.run(*cmd)
  end
end
