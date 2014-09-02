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

require 'rspec/expectations'

RSpec::Matchers.define :match_machinery_show_scope do |expected|
  match do |actual|
    # Remove timestamps which would trigger a failure
    expected.sub!(/(# [A-Za-z ]+ \[)(.*)(\] \()(.*)(\))/, "\\1\\3\\5").strip!
    actual.sub!(/(# [A-Za-z ]+ \[)(.*)(\] \()(.*)(\))/, "\\1\\3\\5").strip!

    # Remove ISO 8601 (and similar) timestamps
    expected.gsub!(/\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}.\d+[Z\-\+ ]+\d{2}:*\d{2}/, "")
    actual.gsub!(/\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}.\d+[Z\-\+ ]+\d{2}:*\d{2}/, "")

    actual == expected
  end

  diffable
end

RSpec::Matchers.define :match_scope do |expected, scope|
  match do |actual|
    actual[scope] == expected[scope]
  end

  failure_message do |actual|
    "expected #{expected[scope]}, got #{actual[scope]}"
  end

  failure_message_when_negated do |actual|
    "expected #{expected[scope]} to not be #{actual[scope]}"
  end

  description do
    "takes two system descriptions and a scope and compares the content of " +
    "the scope between the two descriptions"
  end
end

RSpec::Matchers.define :include_scope do |expected, scope|
  match do |actual|
    if actual[scope].is_a?(Machinery::Object) ||
       actual[scope].is_a?(Machinery::Array)
      expected[scope].all? { |e| actual[scope].include?(e) }
    else
      raise "Scope '#{scope}' has unsupported type '#{actual[scope].class}'"
    end
  end

  failure_message do |actual|
    "expected #{expected[scope]} to be included in #{actual[scope]}"
  end

  failure_message_when_negated do |actual|
    "expected #{expected[scope]} to not be included in #{actual[scope]}"
  end

  description do
    "takes two system descriptions and a scope and checks if the actual " +
    "scope includes the data of the expected scope"
  end
end
