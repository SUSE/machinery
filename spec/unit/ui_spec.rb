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

describe Machinery::Ui do
  describe ".internal_scope_list_to_string" do
    it "accepts strings and converts internal names to cli ones ('_' to '-')" do
      expect(Machinery::Ui.internal_scope_list_to_string("foo_bar")).to eq("foo-bar")
    end

    it "also accepts arrays" do
      expect(Machinery::Ui.internal_scope_list_to_string(["foo_bar", "bar_baz"])).
        to eq("foo-bar, bar-baz")
    end

    it "prints a space after comma" do
      expect(Machinery::Ui.internal_scope_list_to_string(["foo", "bar"])).
        to eq("foo, bar")
    end
  end

  describe ".puts" do
    capture_machinery_output
    it "shows output with linebreak at the end" do
      output = "test output"
      Machinery::Ui.puts(output)
      expect(captured_machinery_output).to eq(output + "\n")
    end
  end

  describe ".print" do
    before(:each) do ||
      allow(Machinery::Ui).to receive(:use_pager).and_return(true)
    end

    let(:output) { "foo bar" }
    it "pipes the output to a pager" do
      ENV['PAGER'] = 'less'

      allow($stdout).to receive(:tty?).and_return(true)
      allow(IO).to receive(:popen)
      allow($?).to receive(:success?).and_return(true)
      expect(IO).to receive(:popen).with("$PAGER", "w").and_return(double(puts: nil, pid: 100))

      Machinery::Ui.puts(output)
    end

    it "raises an error if ENV['PAGER'] is not a valid command" do
      ENV['PAGER'] = 'not_a_pager'

      allow($stdout).to receive(:tty?).and_return(true)

      expect { Machinery::Ui.puts(output) }.
        to raise_error(Machinery::Errors::InvalidPager, /not_a_pager/)
    end

    describe "prints the output to stdout if no pager is available" do
      capture_machinery_output

      it "concatenates the output without adding \n" do
        allow($stdout).to receive(:tty?).and_return(true)
        allow(LocalSystem).to receive(:validate_existence_of_package).
          and_raise(Machinery::Errors::MissingRequirement)
        Machinery::Ui.print("Hello")
        Machinery::Ui.print(" ")
        Machinery::Ui.print("World")
        expect(captured_machinery_output).to eq("Hello World")
      end
    end
  end

  describe ".warn" do
    it "prints warnings to STDERR" do
      expect(STDERR).to receive(:puts).with("foo")

      Machinery::Ui.warn("foo")
    end
  end
end
