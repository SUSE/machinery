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

describe Hint do
  def enable_hints(enabled)
    expect(Machinery::Config).to receive(:new).and_return(double(hints: enabled))
  end

  describe "#get_started" do
    it "prints a hint how to get started if hints are enabled" do
      enable_hints(true)
      expect(Machinery::Ui).to receive(:puts).with(/Hint:.*\n.*inspect HOSTNAME/)
      Hint.get_started
    end

    it "doesn't print a hint how to get started if hints are disabled" do
      enable_hints(false)
      expect(Machinery::Ui).to_not receive(:puts).with(/Hint:.*\n.*inspect HOSTNAME/)
      Hint.get_started
    end
  end

  describe "#show_data" do
    it "prints a hint how to show data if hints are enabled" do
      enable_hints(true)
      expect(Machinery::Ui).to receive(:puts).with(/Hint:.*\n.*show/)
      Hint.show_data(:name => "foo")
    end

    it "doesn't print a hint how to show data if hints are disabled" do
      enable_hints(false)
      expect(Machinery::Ui).to_not receive(:puts).with(/Hint:.*\n.*show/)
      Hint.show_data(:name => "foo")
    end
  end

  describe "#do_complete_inspection" do
    it "prints a hint how to do a complete inspection if hints are enabled" do
      enable_hints(true)
      expect(Machinery::Ui).to receive(:puts).with(
        /Hint:.*\n.*inspect foo --name bar --extract-files/
      )
      Hint.do_complete_inspection(:name => "bar", :host => "foo")
    end

    it "doesn't print a hint how to do a complete inspection if hints are disabled" do
      enable_hints(false)
      expect(Machinery::Ui).to_not receive(:puts).with(
        /Hint:.*\n.*inspect foo --name bar --extract-files/
      )
      Hint.do_complete_inspection(:name => "bar", :host => "foo")
    end
  end
end
