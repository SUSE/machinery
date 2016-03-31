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

module Machinery
  @@logger = nil

  def self.initialize_logger(log_file)
    # We rotate one old log file of 21 MB
    if File.exist?(log_file) && File.size(log_file) > 21 * 1024 * 1024
      rotated_file = log_file + ".0"
      FileUtils.rm(rotated_file) if File.exist?(rotated_file)
      FileUtils.mv(log_file, rotated_file)
    end

    unless File.exist?(log_file)
      dirname = File.dirname(log_file)
      unless Dir.exist?(dirname)
        FileUtils.mkdir_p(dirname)
        File.chmod(0700, dirname)
      end
      FileUtils.touch(log_file)
      FileUtils.chmod(0600, log_file)
    end

    @@logger = Logger.new(log_file)
  end

  def self.logger
    initialize_logger(DEFAULT_LOG_FILE) unless @@logger

    @@logger
  end
end
