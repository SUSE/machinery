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

describe "renderer_helper" do
  it "converts byte numbers to human readable sizes" do
    expect(number_to_human_size("1")).to eq("1 B")
    expect(number_to_human_size("1023")).to eq("1023 B")
    expect(number_to_human_size("1024")).to eq("1 KiB")
    expect(number_to_human_size("1736")).to eq("1.7 KiB")
    expect(number_to_human_size("536870912")).to eq("512 MiB")
    expect(number_to_human_size("36470912")).to eq("34.8 MiB")
    expect(number_to_human_size("1073741824")).to eq("1 GiB")
    expect(number_to_human_size("1273741824")).to eq("1.2 GiB")
    expect(number_to_human_size("1099511627776")).to eq("1 TiB")
    expect(number_to_human_size("1199511627776")).to eq("1.1 TiB")
    expect(number_to_human_size("1599511627776")).to eq("1.5 TiB")
  end
end
