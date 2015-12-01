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


describe ValidateTask, "#validate" do
  capture_machinery_output
  let(:validate_task) { ValidateTask.new }
  let(:store) { SystemDescriptionStore.new("spec/data/schema/") }

  it "raises an error when encountering fauly description" do
    expected = <<EOF
In scope packages: The property #0 (checksum) value "Invalid Checksum" did not match the regex '^[a-f0-9]+$'.

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
