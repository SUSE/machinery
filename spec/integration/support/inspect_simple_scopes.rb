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

shared_examples "inspect simple scope" do |scope, base|
  describe "--scope=#{scope}" do
    it "inspects #{scope}" do
      measure("Inspect #{scope}") do
        expect(
          @machinery.run_command(
            "#{machinery_command} inspect #{@subject_system.ip} " \
              "#{inspect_options if defined?(inspect_options)} " \
              "--scope=#{scope} --name=test",
            as: "vagrant"
          )
        ).to succeed
      end

      expected = File.read("spec/data/#{scope}/#{base}")
      show_command = @machinery.run_command(
        "#{machinery_command} show test --scope=#{scope}",
        as: "vagrant"
      )
      expect(show_command).to succeed
      expect(show_command.stdout).to match_machinery_show_scope(expected)
    end
  end
end

[
  "packages",
  "patterns",
  "repositories",
  "services",
  "os",
  "users",
  "groups"
].each do |scope|
  shared_examples "inspect #{scope}" do |base|
    include_examples("inspect simple scope", scope, base)
  end
end
