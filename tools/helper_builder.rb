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

# This class is used in the machinery-helper/Rakefile to build the helper
class HelperBuilder
  def initialize(helper_dir)
    @helper_dir = helper_dir
    @git_revision_file = File.join(helper_dir, "..", ".git_revision")
    @go_version_file = File.join(helper_dir, "version.go")
  end

  def run_build
    return false if !go_available? || !arch_supported?

    # handle changed branches (where go files are older than the helper)
    if runs_in_git? && (changed_revision? || !File.exist?(@go_version_file))
      write_go_version_file
      if build_machinery_helper
        write_git_revision_file
        return true
      else
        return false
      end
    end

    buildable_archs.each do |arch|
      unless FileUtils.uptodate?(
        File.join(@helper_dir, "machinery-helper-#{arch}"),
        Dir.glob(File.join(@helper_dir, "*.go"))
      )
        return build_machinery_helper
      end
    end
    true
  end

  def write_go_version_file
    file = <<-EOF
// This is a generated file and shouldn't be changed

package main

const VERSION = "#{git_revision}"
    EOF
    File.write(@go_version_file, file)
  end

  def build_machinery_helper
    FileUtils.rm_f(Dir.glob(File.join(@helper_dir, "machinery-helper*")))
    Dir.chdir(@helper_dir) do
      puts("Building machinery-helper binary.")
      if !run_go_build
        STDERR.puts("Warning: Building of the machinery-helper failed!")
        false
      else
        true
      end
    end
  end

  def go_available?
    if !run_which_go
      STDERR.puts(
        "Error: The official Go compiler is not available on this system which prevents the" \
          " machinery-helper from being built.\nInspection of unmanaged-files is" \
          " not possible without this helper."
      )
      false
    else
      true
    end
  end

  def buildable_archs
    if @archs.nil?
      version = run_go_version[/go(\d+.\d)/, 1].to_f
      @archs = if version <= 1.4
        case run_uname_p
        when "x86_64"
          ["x86_64"]
        when "i686"
          ["i686"]
        else
          []
        end
      elsif version <= 1.6
        archs = ["i686", "x86_64", "ppc64le"]
        # the two following lines are temporary until Go 1.7 with s390x support is released
        archs.push("s390x") if File.exist?("/usr/share/go/src/cmd/asm/internal/arch/s390x.go")
        archs
      else
        ["i686", "x86_64", "ppc64le", "s390x"]
      end
    end
    @archs
  end

  def arch_supported?
    arch = run_uname_p
    if buildable_archs.include?(arch)
      true
    else
      STDERR.puts(
        "Error: The hardware architecture #{arch} is not yet supported by the official GO" \
          " Compiler so the machinery-helper can not be built."
      )
      false
    end
  end

  def runs_in_git?
    Dir.exist?(File.join(@helper_dir, "..", ".git")) && system("which git > /dev/null 2>&1")
  end

  def write_git_revision_file
    File.write(@git_revision_file, git_revision)
  end

  def changed_revision?
    if File.exist?(@git_revision_file)
      old_revision = File.read(@git_revision_file)
    else
      old_revision = "unknown"
    end
    git_revision != old_revision
  end

  private

  def run_go_version
    `go version`
  end

  def convert_to_go_arch(arch)
    case arch
    when "x86_64"
      "amd64"
    when "i686"
      "386"
    else
      arch
    end
  end

  def run_go_build
    if buildable_archs.count == 1
      system("go build -o machinery-helper-#{buildable_archs.first}")
    else
      buildable_archs.each do |arch|
        system(
          "env GOOS=linux GOARCH=#{convert_to_go_arch(arch)} go build -o machinery-helper-#{arch}"
        )
      end
    end
  end

  def git_revision
    `git rev-parse HEAD`.chomp
  end

  def run_which_go
    system("which go > /dev/null 2>&1")
  end

  def run_uname_p
    `uname -p`.chomp
  end
end
