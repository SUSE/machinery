#  Copyright (c) 2013-2015 SUSE LLC
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 3 of the GNU General Public License as
#  published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.
#
#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

shared_examples "serve html" do
  describe "serve html" do
    before(:each) do
      @system_description_file = "spec/data/descriptions/jeos/manifest.json"
      @system_description_dir = File.dirname(@system_description_file)
      @system_description = create_test_description(json: File.read(@system_description_file))
    end

    it "makes the system description HTML available at the specified port" do
      @machinery.inject_directory(
        @system_description_dir,
        machinery_config[:machinery_dir],
        owner: machinery_config[:owner],
        group: machinery_config[:group]
      )

      cmd = "#{machinery_command} serve jeos --port 5000"
      Thread.new do
        @machinery.run_command(cmd)
      end

      begin
        wait_time = 0
        loop do
          curl_command = @machinery.run_command("curl http://localhost:5000/jeos")

          if curl_command.stderr =~ /Failed to connect/
            raise "Could not connect to webserver" if wait_time >= 10
            puts "not connected. retry"

            sleep 0.5
            wait_time += 0.5
            next
          end

          expect(curl_command).to succeed.with_stderr.and have_stdout(/<title>.*jeos - Machinery System Description.*<\/title>/m)
          break
        end
      ensure
        # Kill the webserver again
        @machinery.run_command("pkill -f '#{cmd}'")
      end
    end
  end
end
