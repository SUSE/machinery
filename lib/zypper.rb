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

  def self.isolated(&block)
    Dir.mktmpdir("machinery_zypper") do |zypper_base|
      zypper = Zypper.new

      [
        "#{zypper_base}/packages",
        "#{zypper_base}/solv",
        "#{zypper_base}/repos"
      ].each do |dir|
        FileUtils.mkdir_p(dir)
      end

      zypper.zypper_options = [
        "--non-interactive",
        "--no-gpg-checks",
        "--cache-dir",      "#{zypper_base}",
        "--pkg-cache-dir",  "#{zypper_base}/packages",
        "--solv-cache-dir", "#{zypper_base}/solv",
        "--reposd-dir",     "#{zypper_base}/repos",
        "--config",         "#{zypper_base}/zypp.conf"
      ]

      block.call(zypper)
    end
  end

  private

  def call_zypper(*args)
    cmd = ["sudo", "zypper"]
    cmd += @zypper_options if @zypper_options
    cmd += args

    LoggedCheetah.run(*cmd)
  end
end
