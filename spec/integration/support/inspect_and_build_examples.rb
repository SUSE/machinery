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

shared_examples "inspect and build" do |bases|
  bases.each do |base|
    describe "rebuild inspected system", slow: true do
      before(:all) do
        @subject_system = start_system(box: base, username: "machinery", password: "linux")
        prepare_machinery_for_host(
          @machinery, @subject_system.ip, username: "machinery", password: "linux"
        )

        # Enabled experimental features so that the --exclude option can be used
        expect(
          @machinery.run_command("machinery config experimental-features on", as: "vagrant")
        ).to succeed
      end

      it "inspects" do
        measure("Inspect") do
          expect(
            @machinery.run_command(
              "machinery --exclude=/packages/name=test-quote-char inspect #{@subject_system.ip} " \
              " -x --name=build_test --remote-user=machinery",
              as: "vagrant"
            )
          ).to succeed.with_stderr
        end
      end

      it "builds" do
        measure("Build") do
          expect(
            @machinery.run_command(
              "machinery build -i /home/vagrant/build_image -d -s " \
              "> /tmp/#{base}-build.log build_test",
              as: "vagrant"
            )
          ).to succeed
        end
      end

      it "extracts and boots" do
        measure("Extract and boot") do
          find_command = @machinery.run_command(
            "find", "/home/vagrant/build_image", "-name", "*qcow2"
          )
          expect(find_command).to succeed.and include_stdout("qcow2")

          image = find_command.stdout.split.first.chomp
          local_image = File.join("/tmp", File.basename(image))
          `sudo rm #{local_image}` if File.exists?(local_image)
          @machinery.extract_file image, "/tmp"

          @test_system = start_system(
            image: local_image, skip_ssh_setup: true, username: "machinery", password: "linux"
          )

          # Run 'ls' via ssh in the built system to verify its booted and accessible.
          expect(
            @machinery.run_command("ls", "/tmp")
          ).to succeed
        end
      end
    end
  end
end

