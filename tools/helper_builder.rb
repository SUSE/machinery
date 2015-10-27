# encoding:utf-8

# Copyright (c) 2013-2015 SUSE LLC
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
    # An unsupported architecture is no error
    return true if !arch_supported?
    return false if !go_available?

    # handle changed branches (where go files are older than the helper)
    if runs_in_git? && changed_revision?
      write_go_version_file
      if build_machinery_helper
        write_git_revision_file
        return true
      else
        return false
      end
    end

    if !FileUtils.uptodate?(
      File.join(@helper_dir, "machinery-helper"), Dir.glob(File.join(@helper_dir, "*.go"))
    )
      return build_machinery_helper
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
    FileUtils.rm_f(File.join(@helper_dir, "machinery-helper"))
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
        "Warning: The Go compiler is not available on this system. Skipping building the" \
          " machinery-helper.\nThe machinery-helper increases the inspection speed significantly."
      )
      false
    else
      true
    end
  end

  def arch_supported?
    arch = run_uname_p
    if !["x86_64"].include?(arch)
      STDERR.puts(
        "Warning: The hardware architecture #{arch} is not yet supported by the machinery-helper."
      )
      false
    else
      true
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

  def run_go_build
    system("go build")
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
