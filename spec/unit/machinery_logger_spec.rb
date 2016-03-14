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

require_relative "spec_helper"

describe "Machinery.logger" do
  include_context "machinery test directory"

  around(:each) do |example|
    old_logger = Machinery.class_variable_get("@@logger")
    Machinery.class_variable_set("@@logger", nil)

    example.call

    Machinery.class_variable_set("@@logger", old_logger)
  end

  it "logs to ~/.machinery/machinery.log" do
    expect(Logger).to receive(:new).with(File.expand_path("~/.machinery/machinery.log"))

    Machinery.logger
  end

  it "creates the log directory with mode 0700" do
    log_file = "/tmp/machinery_mode_check/machinery.log"
    log_dir  = File.dirname(log_file)
    expect(Dir.exist?(log_dir)).to be(false)
    expect(Logger).to receive(:new).with(log_file)

    Machinery.initialize_logger(log_file)
    expect(Dir.exist?(log_dir)).to be(true)
    expect(File.stat(log_dir).mode.to_s(8)).to eq("100700")
  end
end
