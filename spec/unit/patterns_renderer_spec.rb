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

describe PatternsRenderer do
  describe "#render" do
    context "when showing an rpm-based system" do
      let(:system_description) { create_test_description(scopes: ["patterns"]) }

      it "prints a pattern list" do
        output = PatternsRenderer.new.render(system_description)

        expect(output).to include("base\n")
        expect(output).to include("Minimal\n")
      end

      it "does not show the dpkg message" do
        output = subject.render(system_description)

        expect(output).not_to include("Note: Tasks on Debian-like systems are treated as patterns.")
      end

      it "does show pattern_sytem zypper" do
        output = subject.render(system_description)

        expect(output).to include("Pattern Manager: zypper")
      end

      context "when there are no patterns" do
        let(:system_description) { create_test_description(scopes: ["empty_patterns"]) }

        it "shows a message" do
          output = subject.render(system_description)

          expect(output).to include("There are no patterns or tasks.")
        end
      end
    end

    context "when showing a Debian based system" do
      let(:system_description) { create_test_description(scopes: ["patterns_with_dpkg"]) }

      it "shows a note" do
        output = subject.render(system_description)

        expect(output).to include("Note: Tasks on Debian-like systems are treated as patterns.")
      end

      it "does show pattern_sytem tasksel" do
        output = subject.render(system_description)

        expect(output).to include("Pattern Manager: tasksel")
      end
    end
  end
end
