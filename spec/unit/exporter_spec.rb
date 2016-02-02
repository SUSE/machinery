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

describe Exporter do
  describe "#quote" do
    it "returns the quoted name" do
      expect(subject.quote("/bla/single-quote-file'-foo/")).to eq(
        "/bla/single-quote-file'\\''-foo/"
      )
    end

    it "returns the name without escaping anything" do
      expect(subject.quote("/bla/no-single-quote-file-foo/")).to eq(
        "/bla/no-single-quote-file-foo/"
      )
    end
  end
end
