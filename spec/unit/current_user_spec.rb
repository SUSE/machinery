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

describe CurrentUser do
  subject { CurrentUser.new }

  describe "#is_root?" do
    it "returns true if EUID of the current process is 0" do
      allow(Process).to receive(:euid).and_return(0)

      expect(subject.is_root?).to be(true)
    end

    it "returns false if EUID of the current process isn't 0" do
      allow(Process).to receive(:euid).and_return(1)

      expect(subject.is_root?).to be(false)
    end
  end
end
