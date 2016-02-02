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

describe ManTask do
  describe "#man" do
    context "on the console" do
      it "validates the availability of man by calling the 'validate_existence_of_package method'" do
        expect(LocalSystem).to receive(:validate_existence_of_package).with("man")
        allow_any_instance_of(Kernel).to receive(:system).with("man", anything)

        subject.man({})
      end

      it "calls the machinery man page" do
        allow(LocalSystem).to receive(:validate_existence_of_package).with("man")
        expect(subject).to receive("system").
          with("man", anything)

        subject.man({})
      end
    end

    context "in the browser" do
      include GivenFilesystemSpecHelpers
      use_given_filesystem
      silence_machinery_output

      before(:each) do
        stub_const("Machinery::ROOT", given_directory)
      end

      it "shows an error and exits if the documentation does not exist" do
        expect(Html).to_not receive(:run_server)
        expect(Machinery::Ui).to receive(:warn)

        subject.man(html: true)
      end

      it "opens the documentation in the browser if it exists" do
        FileUtils.mkdir_p(File.join(Machinery::ROOT, "manual", "site"))
        expect(Html).to receive(:run_server).and_return(double(join: nil))


        subject.man(html: true)
      end
    end
  end
end
