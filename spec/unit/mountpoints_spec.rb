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

require_relative "spec_helper"

describe MountPoints do
  subject {
    system = System.new
    allow(system).to receive(:read_file).with("/proc/mounts").
      and_return(File.open("spec/data/unmanaged_files/proc_mounts"))

    MountPoints.new(system)
  }

  describe "#all" do
    it "returns an array containing all mount points" do
      expect(subject.all).to match_array(["/",  "/data", "/dev", "/homes/tux"])
    end
  end

  describe "#remote" do
    it "returns an array containing the remote mount points" do
      expect(subject.remote).to match_array(["/homes/tux"])
    end
  end

  describe "#local" do
    it "returns an array containing the local mount points" do
      expect(subject.local).to match_array(["/", "/data"])
    end
  end
end
