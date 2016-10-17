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

describe Machinery::RemoveTask do
  capture_machinery_output
  include_context "machinery test directory"

  let(:remove_task) { Machinery::RemoveTask.new }
  let(:store) { SystemDescriptionStore.new(test_base_path) }

  describe "#remove" do
    it "removes the system description directory" do
      create_machinery_dir
      expect(store.list).to include(test_name)
      remove_task.remove(store, test_name)
      expect(store.list).to be_empty
    end

    it "removes all system descriptions" do
      create_machinery_dir
      expect(store.list).to include(test_name)
      remove_task.remove(store, nil, all: true)
      expect(store.list).to be_empty
    end

    it "shows also a success message if verbose is true" do
      create_machinery_dir
      remove_task.remove(store, test_name, verbose: true)
      expect(captured_machinery_output).to include(
        "System description '#{test_name}' successfully removed."
      )
    end

    it "throws an error when SystemDescription does not exist" do
      expect {
        remove_task.remove(store, "foo_bar_does_not_exist")
      }.to raise_error(Machinery::Errors::SystemDescriptionNotFound)
    end

    it "throws an error when SystemDescription does not exist but deletes all given" do
      create_machinery_dir("description1")
      expect(store.list).to match_array(["description1"])
      expect {
        remove_task.remove(store, ["foo_bar_does_not_exist", "description1"])
      }.to raise_error(Machinery::Errors::SystemDescriptionNotFound)
      expect(store.list).to be_empty
    end

    it "removes all given SystemDescription directorys" do
      create_machinery_dir("description1")
      create_machinery_dir("description2")
      expect(store.list).to match_array(["description1", "description2"])
      remove_task.remove(store, ["description1", "description2"])
      expect(store.list).to be_empty
    end
  end
end
