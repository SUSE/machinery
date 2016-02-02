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

# Rpm represents an RPM package on the disk.
class Rpm
  def initialize(path)
    @path = path
  end

  def diff(file, local_file)
    begin
      cpio = LoggedCheetah.run("rpm2cpio", @path, stdout: :capture)
      original_config = LoggedCheetah.run(
        "cpio", "-iv", "--to-stdout", ".#{file}", stdin: cpio, stdout: :capture
      )
    rescue Cheetah::ExecutionFailed => e
      Machinery.logger.error(e.stderr)
      return nil
    end

    begin
      LoggedCheetah.run(
        "diff", "-u", "--label", "#{File.join("a", file)}", "--from-file=-",
         "--label", "#{File.join("b", file)}", local_file,
        stdin: original_config,
        stdout: :capture
      )
    rescue Cheetah::ExecutionFailed => e
      # diff exits with 1 when there are changes
      if e.status.exitstatus == 1
        e.stdout
      else
        Machinery.logger.error(e.stderr)
        return nil
      end
    end
  end
end
