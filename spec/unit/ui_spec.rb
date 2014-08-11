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

describe Machinery::Ui do
  describe ".internal_scope_list_to_string" do
    it "accepts strings and converts internal names to cli ones ('_' to '-')" do
      expect(Machinery::Ui.internal_scope_list_to_string("foo_bar")).to eq("foo-bar")
    end

    it "also accepts arrays" do
      expect(Machinery::Ui.internal_scope_list_to_string(["foo_bar", "bar_baz"])).
        to eq("foo-bar,bar-baz")
    end
  end

  describe ".prints_output" do
    let(:output) { "foo bar" }
    it "pipes the output to a pager" do
      ENV['PAGER'] = 'less'

      allow($stdout).to receive(:tty?).and_return(true)
      allow(IO).to receive(:popen)
      allow($?).to receive(:success?).and_return(true)
      expect(IO).to receive(:popen).with("$PAGER", "w")

      Machinery::Ui.print_output(output)
    end

    it "prints the output to stdout if no pager is available" do
      ENV['PAGER'] = nil

      allow($stdout).to receive(:tty?).and_return(true)
      allow(Machinery).to receive(:check_package).
        and_raise(Machinery::Errors::MissingRequirement)
      expect($stdout).to receive(:puts).with(output)

      Machinery::Ui.print_output(output)
    end

    it "raises an error if ENV['PAGER'] is not a valid command" do
      ENV['PAGER'] = 'not_a_pager'

      allow($stdout).to receive(:tty?).and_return(true)

      expect { Machinery::Ui.print_output(output) }.
        to raise_error(Machinery::Errors::InvalidPager, /not_a_pager/)
    end
  end
end
