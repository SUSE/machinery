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

describe Machinery::Errors::SystemDescriptionValidationFailed do
  it "lists errors" do
    errors = ["Message One", "Message Two"]
    e = Machinery::Errors::SystemDescriptionValidationFailed.new(errors)
    expect(e.to_s).to eq(<<-EOT
Message One
Message Two
EOT
    )
  end

  it "shows header" do
    errors = ["Message One", "Message Two"]
    e = Machinery::Errors::SystemDescriptionValidationFailed.new(errors)
    e.header = "HEADER"
    expect(e.to_s).to eq(<<-EOT
HEADER

Message One
Message Two
EOT
    )
  end
end
