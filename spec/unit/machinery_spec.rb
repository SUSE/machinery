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

require_relative "spec_helper"

describe "machinery" do
  include GivenFilesystemSpecHelpers
  use_given_filesystem

  it "logs to the logfile in MACHINERY_LOG_FILE" do
    log_file = given_dummy_file
    `MACHINERY_LOG_FILE=#{log_file} #{File.join(Machinery::ROOT, "bin", "machinery")} --version`
    logged_line = File.readlines(log_file).last

    # Example of expected log line:
    #
    # I, [2014-02-27T15:59:21.630562 #2648]  INFO -- : Executing '/space/machinery/bin/machinery --version'...
    expect(logged_line).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.*#\d+.*INFO.*Executing \(Version \d+\.\d+\.\d+\).*machinery --version/)
  end
end
