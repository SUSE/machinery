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

describe Machinery::Errors::MissingExtractedFiles do
  let (:name) { "name" }
  let (:scopes) { ["config_files", "changed_managed_files"] }
  let (:description) { create_test_description(name: name, scopes: scopes) }

  it "shows message about missing files and how to extract them" do
    e = Machinery::Errors::MissingExtractedFiles.new(description, scopes)
    expect(e.to_s).
      to eq(
        "The following scopes 'config-files, changed-managed-files' are part of the " \
        "system description" \
        " but the corresponding files weren't extracted during inspection.\n" \
        "The files are required to continue with this command. " \
        "Run `#{$0} inspect --extract-files --scope=config-files, changed-managed-files " \
        "--name='#{name}' example.com` to extract them."
      )
  end

  it "adapts the message if only one scope is affected" do
    e = Machinery::Errors::MissingExtractedFiles.new(description, ["config_files"])
    expect(e.to_s).
      to eq(
        "The scope 'config-files' is part of the system description" \
        " but the corresponding files weren't extracted during inspection.\n" \
        "The files are required to continue with this command. " \
        "Run `#{$0} inspect --extract-files --scope=config-files --name='#{name}' example.com` to extract them."
      )
  end

  it "shows an error with the --name parameter when the name and hostname differ" do
    e = Machinery::Errors::MissingExtractedFiles.new(description, scopes)
    expect(e.to_s).
      to include(" --name='#{name}' example.com")
  end

  it "shows an error without the --name parameter if they are identical" do
    description.name = "example.com"
    e = Machinery::Errors::MissingExtractedFiles.new(description, scopes)
    expect(e.to_s).
      not_to include(" --name=")
  end

  it "shows placeholder '<HOSTNAME>' if no hostname is available" do
    scopes.each do |scope|
      description[scope].meta.hostname = nil
    end
    e = Machinery::Errors::MissingExtractedFiles.new(description, scopes)
    expect(e.to_s).
      to include(" <HOSTNAME>")
  end
end

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
