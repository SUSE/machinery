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

include ChangedRpmFilesHelper

describe "parse_rpm_changes_line" do
  silence_machinery_output

  it "parses an md5 change" do
    line = "..5......  c /etc/pulse/client.conf"
    file, changes, flag = parse_rpm_changes_line(line)
    expect(file).to eq("/etc/pulse/client.conf")
    expect(changes).to eq(["md5"])
    expect(flag).to eq("c")
  end

  it "parses all changes" do
    line = "SM5DLUGTP  c /etc/pulse/client.conf"
    file, changes, flag = parse_rpm_changes_line(line)
    expect(file).to eq("/etc/pulse/client.conf")
    expect(changes).to eq(
      ["size", "mode", "md5", "device_number", "link_path", "user", "group", "time", "capabilities"]
    )
    expect(flag).to eq("c")
  end

  it "parses an unknown change" do
    line = "........S  c /etc/pulse/client.conf"
    file, changes, flag = parse_rpm_changes_line(line)
    expect(file).to eq("/etc/pulse/client.conf")
    expect(changes).to eq(["other_rpm_changes"])
    expect(flag).to eq("c")
  end

  it "shows a warning when an rpm test could not be performed" do
    line = "..?......  c /etc/pulse/client.conf"
    expect(Machinery::Ui).to receive(:warn).with("Warning: Could not perform all tests on "\
      "rpm changes for file '/etc/pulse/client.conf'.")
    _, _, _ = parse_rpm_changes_line(line)
  end
end
