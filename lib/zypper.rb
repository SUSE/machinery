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
  attr_accessor :zypp_base

  class <<self
    def isolated(options = {}, &block)
      zypper = Zypper.new
      zypper.zypp_base = Dir.mktmpdir("machinery_zypper")

      zypper.zypper_options = [
        "--non-interactive",
        "--no-gpg-checks",
        "--root", zypper.zypp_base
      ]

      if options[:arch]
        zypper.zypp_config = create_zypp_config(zypper.zypp_base, options[:arch])
      end

      block.call(zypper)
    ensure
      clean_up(zypper)
    end

    private

    def clean_up(zypper)
      unless zypper.zypp_base =~ /^\/tmp\/machinery_zypper/
        raise("The zypper base directory is not inside of '/tmp'. Aborting...")
      end
      cmd = ["rm", "-rf", zypper.zypp_base]
      cmd = cmd.insert(0, "sudo") if zypper.contains_nfs_repos?
      LoggedCheetah.run(*cmd)
    end

    def create_zypp_config(zypp_base, arch)
      zypp_dir = File.join(zypp_base, "/etc/zypp")
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
    call_zypper "refresh", sudo: contains_nfs_repos?
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

  def contains_nfs_repos?
    files = Dir.glob(File.join(@zypp_base, "etc/zypp/repos.d", "*"))
    files.any? do |file|
      File.readlines(file).any? { |line| line.start_with?("baseurl=nfs://") }
    end
  end

  private

  def call_zypper(*args)
    sudo = args.last.delete(:sudo) if args.last.is_a?(Hash)

    cmd = ["zypper"]
    cmd.unshift("sudo") if sudo
    cmd += @zypper_options if @zypper_options
    cmd += args

    with_env "ZYPP_CONF" => @zypp_config do
      LoggedCheetah.run(*cmd)
    end
  end
end
