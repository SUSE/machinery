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


describe GenerateHtmlTask do
  initialize_system_description_factory_store
  capture_machinery_output


  subject { GenerateHtmlTask.new }
  let(:description) { create_test_description(store_on_disk: true) }

  describe "#generate" do
    it "triggers a html generation" do
      expect(Html).to receive(:generate).with(description)

      subject.generate(description)
    end

    it "shows an output where the html file is stored" do
      subject.generate(description)
      expect(captured_machinery_output).to match(
        "The generated HTML file is stored in: \n"
      )
    end

    it "returns the path where the html file is stored" do
      subject.generate(description)

      expect(captured_machinery_output).to match(
        "The generated HTML file is stored in: \n" \
        "#{description.store.description_path(description.name)}"
      )
    end
  end
end
