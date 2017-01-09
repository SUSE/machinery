# encoding:utf-8

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

# This class is used to build the helper binaries with Go

class Go
  def archs
    @archs ||= case
    when version <= 1.4
      ["i686", "x86_64"].include?(local_arch) ? [local_arch] : []
    when version == 1.6 && suse_package_includes_s390?
      ["i686", "x86_64", "ppc64le", "s390x", "armv6l", "armv7l", "aarch64"]
    when version <= 1.6
      ["i686", "x86_64", "ppc64le", "armv6l", "armv7l", "aarch64"]
    when version >= 1.7
      ["i686", "x86_64", "ppc64le", "s390x", "armv6l", "armv7l", "aarch64"]
    end
  end

  def build
    if archs.count == 1
      arch = archs.first
      puts("Building machinery-helper for architecture #{arch}.")
      system("go build -o machinery-helper-#{arch}")
    else
      archs.each do |arch|
        puts("Building machinery-helper for architecture #{arch}.")
        system(
          "env GOOS=linux #{compile_options(arch)} go build -o machinery-helper-#{arch}"
        )
      end
    end
  end

  def available?
    if run_which_go
      true
    else
      STDERR.puts(
        "ERROR: The official Go compiler is not available on this system which prevents the" \
          " machinery-helper binaries from being built."
      )
      false
    end
  end

  private

  def version
    @version ||= run_go_version[/go(\d+.\d)/, 1].to_f
  end

  def suse_package_includes_s390?
    File.exist?("/usr/share/go/src/cmd/asm/internal/arch/s390x.go")
  end

  def compile_options(arch)
    # check https://golang.org/doc/install/source#environment
    additional_options = ""
    compile_arch = case arch
    when "x86_64"
      "amd64"
    when "i686"
      "386"
    when "aarch64"
      "arm64"
    when "armv6l"
      additional_options = " GOARM=6"
      "arm"
    when "armv7l"
      additional_options = " GOARM=7"
      "arm"
    else
      arch
    end

    "GOARCH=#{compile_arch}#{additional_options}"
  end

  def run_go_version
    `go version`
  end

  def local_arch
    @local_arch ||= `uname -p`.chomp
  end

  def run_which_go
    system("which go > /dev/null 2>&1")
  end
end
