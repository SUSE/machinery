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


describe Machinery::ValidateTask, "#validate" do
  capture_machinery_output
  let(:validate_task) { Machinery::ValidateTask.new }
  let(:store) { Machinery::SystemDescriptionStore.new("spec/data/schema/") }

  it "raises an error when encountering faulty description" do
    expected = <<EOF
In scope packages: The property #0 (_elements/checksum/_attributes/package_system) of type Hash did not match any of the required schemas.

EOF
    expected.chomp!
    expect {
      validate_task.validate(store, "faulty_description")
    }.to raise_error(Machinery::Errors::SystemDescriptionValidationFailed, expected)
  end

  it "prints a message in case of successful validation" do
    validate_task.validate(store, "valid_description")

    expect(captured_machinery_output).to include("Validation succeeded")
  end

  it "prints a message in case of failed validation" do
    expect {
      validate_task.validate(store, "faulty_description")
    }.to raise_error(Machinery::Errors::SystemDescriptionError)

    expect(captured_machinery_output).to include("Validation failed")
  end
end
