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

# Zypper is a wrapper class around the zypper package manager
#
# Zypper offers access to the system-wide zypper environment, but it also allows
# for running zypper in an isolated environment using 'Zypper.isolated'.
# That way Machinery can safely add repositories and download packages without
# polluting the host.
class Zypper
  attr_accessor :zypper_options
  attr_accessor :zypp_config

  class <<self
    def isolated(options = {}, &block)
      Dir.mktmpdir("machinery_zypper") do |zypper_base|
        zypper = Zypper.new

        zypper.zypper_options = [
          "--non-interactive",
          "--no-gpg-checks",
          "--root", zypper_base
        ]

        if options[:arch]
          zypper.zypp_config = create_zypp_config(zypper_base, options[:arch])
        end

        block.call(zypper)
      end
    end

    private

    def create_zypp_config(base_path, arch)
      zypp_dir = File.join(base_path, "/etc/zypp")
      zypp_config = File.join(zypp_dir, "zypp.conf")

      FileUtils.mkdir_p(zypp_dir)

      File.write(zypp_config,
        "[main]\n" \
        "arch=#{arch}"
      )

      zypp_config
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
    raw_xml = call_zypper "-x", "download", package, stdout: :capture

    xml = REXML::Document.new(raw_xml)
    xml.elements["//localfile"].attributes["path"] if xml.elements["//localfile"]
  end

  def version
    version = call_zypper "--version", stdout: :capture
    found = version.match(/zypper (\d+)\.(\d+)\.(\d+)/)
    [found[1].to_i, found[2].to_i, found[3].to_i] if found
  end

  private

  def call_zypper(*args)
    cmd = ["zypper"]
    cmd += @zypper_options if @zypper_options
    cmd += args

    with_env "ZYPP_CONF" => @zypp_config do
      LoggedCheetah.run(*cmd)
    end
  end
end
