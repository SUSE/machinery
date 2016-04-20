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

shared_examples "inspect" do |base|
  username = "root"
  password = "vagrant"

  describe "inspect #{base} system" do
    let(:inspect_options) {
      "--remote-user=#{username}" if username != "root"
    }
    before(:all) do
      @subject_system = start_system(
        box: base,
        username: username,
        password: password
      )
      prepare_machinery_for_host(
        @machinery,
        @subject_system.ip,
        username: username,
        password: password
      )
    end

    after(:all) do
      @machinery.run_command("machinery", "remove", base, as: "vagrant")
    end

    include_examples "inspect packages", base
    include_examples "inspect patterns", base
    include_examples "inspect repositories", base
    include_examples "inspect os", base
    include_examples "inspect services", base
    include_examples "inspect users", base
    include_examples "inspect groups", base
    include_examples "inspect changed config files", base
    include_examples "inspect changed managed files", base
    include_examples "inspect unmanaged files", base, true

    context "`show` hint" do
      it "will not be shown when --show is used" do
        expect(
          @machinery.run_command(
            "#{machinery_command} inspect #{@subject_system.ip} --scope=users --name=test --show",
            as: "vagrant"
          )
        ).to succeed.and not_include_stdout("To show the data of the system you just inspected run")
      end

      it "will be shown when --show is not used" do
        expect(
          @machinery.run_command(
            "#{machinery_command} inspect #{@subject_system.ip} --scope=users --name=test",
            as: "vagrant"
          )
        ).to succeed.and include_stdout("To show the data of the system you just inspected run")
      end
    end
  end
end
