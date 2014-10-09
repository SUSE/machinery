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

shared_examples "inspect and build" do |bases|
  bases.each do |base|
    describe "rebuild inspected system" do
      before(:all) do
        @subject_system = start_system(box: base)
        prepare_machinery_for_host(@machinery, @subject_system.ip, password: "vagrant")
      end

      it "inspects" do
        measure("Inspect") do
          @machinery.run_command(
              "machinery inspect #{@subject_system.ip} -x --name=build_test",
              :as => "vagrant",
              :stdout => :capture
          )
        end
      end

      it "builds", :slow_test => true do
        measure("Build") do
          @machinery.run_command(
              "machinery build -i /home/vagrant/build_image -d -s > /tmp/#{base}-build.log build_test",
              :as => "vagrant",
              :stdout => :capture
          )
        end
      end

      it "Extracts and boots", :slow_test => true do
        measure("Extract and boot") do
          images = @machinery.run_command(
            "find", "/home/vagrant/build_image", "-name", "*qcow2", :stdout => :capture
          )
          expect(images).not_to be_empty

          image = images.split.first.chomp
          local_image = File.join("/tmp", File.basename(image))
          `sudo rm #{local_image}` if File.exists?(local_image)
          @machinery.extract_file image, "/tmp"

          @test_system = start_system(image: local_image, skip_ssh_setup: true)

          @machinery.run_command(
              "ls", "/tmp", :stdout => :capture
          )
        end
      end
    end
  end
end

