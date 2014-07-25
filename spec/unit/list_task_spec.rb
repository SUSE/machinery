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

describe ListTask do
  include FakeFS::SpecHelpers
  let(:list_task) { ListTask.new }
  let(:store) { SystemDescriptionStore.new }
  let(:name) { "foo" }
  let(:date) { "2014-02-07T14:04:45Z" }
  let(:date_human) { Time.parse(date).localtime.strftime "%Y-%m-%d %H:%M:%S" }
  let(:system_description) {
    json = <<-EOF
      {
        "packages": [],
        "repositories": [],
        "meta": {
          "packages": {
            "modified": "#{date}"
          },
          "repositories": {
            "modified": "#{date}"
          }
        }
      }
    EOF
    SystemDescription.from_json(name, json)
  }
  let(:system_description_without_meta) {
    json = <<-EOF
      {
        "packages": []
      }
    EOF
    SystemDescription.from_json(name, json)
  }
  let(:system_description_with_extracted_files) {
    json = <<-EOF
      {
        "config-files": []
      }
    EOF
    SystemDescription.from_json(name, json)
  }

  describe "#list" do
    it "lists the system descriptions with scopes" do
      store.save(system_description)
      expect($stdout).to receive(:puts) { |s|
        expect(s).to include(name)
        expect(s).to include("packages")
        expect(s).to include("repositories")
        expect(s).not_to include(date_human)
      }
      list_task.list(store)
    end

    it "shows also the date of the descriptions if verbose is true" do
      store.save(system_description)
      expect($stdout).to receive(:puts) { |s|
        expect(s).to include(name)
        expect(s).to include(date_human)
      }
      list_task.list(store, {"verbose" => true})
    end

    it "verbose shows the date as unknown if there is no meta data for it" do
      store.save(system_description_without_meta)
      expect($stdout).to receive(:puts) { |s|
        expect(s).to include(name)
        expect(s).to include("unknown")
      }
      list_task.list(store, {"verbose" => true})
    end

    it "marks scopes with exctracted files as such" do
      expect(store).to receive(:file_store).and_return(double)
      expect($stdout).to receive(:puts) { |s|
        expect(s).to include(name)
        expect(s).to include("config-files (extracted)")
      }

      store.save(system_description_with_extracted_files)
      list_task.list(store)
    end
  end
end
