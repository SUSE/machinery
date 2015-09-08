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
    let(:system_description_dir) {
      system_description_file = File.join(Machinery::ROOT,
        "spec/data/descriptions/jeos/opensuse131/manifest.json")
      File.dirname(system_description_file)
    }
    let(:config_tmp_file) { "/tmp/machinery/config" }

    def test_basic_html(port)
      wait_time = 0
      loop do
        curl_command = @machinery.run_command("curl http://localhost:#{port}/opensuse131")

        if curl_command.stderr =~ /Failed to connect/
          raise "Could not connect to webserver" if wait_time >= 10

          sleep 0.5
          wait_time += 0.5
          next
        end

        expect(curl_command).to succeed.with_stderr.
          and have_stdout(/<title>.*opensuse131 - Machinery System Description.*<\/title>/m)
        break
      end
    end

    after(:each) do
      @machinery.run_command("pkill -f 'machinery serve' --signal 9")
    end

    before(:each) do
      @machinery.inject_directory(
        system_description_dir,
        machinery_config[:machinery_dir],
        owner: machinery_config[:owner],
        group: machinery_config[:group]
      )
    end

    it "makes the system description HTML and extracted files available at the specified port" do
      cmd = "#{machinery_command} serve opensuse131 --port 5000"
      Thread.new do
        @machinery.run_command(cmd)
      end

      test_basic_html(5000)

      # Test file content download
      expected_content = File.read(
        File.join(system_description_dir, "config_files", "etc", "crontab")
      )
      curl_command = @machinery.run_command(
        "curl http://localhost:5000/descriptions/opensuse131/files/config_files/etc/crontab"
      )
      expect(curl_command).to succeed.with_stderr.and have_stdout(expected_content)
    end

    it "makes the system description HTML available at the config-file port" do
      @machinery.run_command("MACHINERY_CONFIG_FILE=#{config_tmp_file} #{machinery_command} config http-server-port=7500")

      cmd = "#{machinery_command} serve opensuse131"

      Thread.new do
        @machinery.run_command("MACHINERY_CONFIG_FILE=#{config_tmp_file} #{cmd}")
      end

      test_basic_html(7500)
      @machinery.run_command("rm -f '#{config_tmp_file}'")
    end

    it "makes sure a port can't be used twice" do
      cmd = "#{machinery_command} serve --ip 127.0.0.1 --port 5000 opensuse131"
      Thread.new do
        @machinery.run_command(cmd)
      end

      wait_time = 0

      loop do
        curl_command = @machinery.run_command("curl http://127.0.0.1:5000/opensuse131")

        if curl_command.stderr =~ /Failed to connect/
          raise "Could not connect to webserver" if wait_time >= 10

          sleep 0.5
          wait_time += 0.5
          next
        end

        break
      end

      expect(@machinery.run_command(cmd)).to fail.and have_stderr(/Port 5000 is already in use.\n/)
    end

    it "checks for the correctness of hostnames" do
      cmd = "#{machinery_command} serve --ip blabla --port 5000 opensuse131"
      expect(@machinery.run_command(cmd)).to fail.and \
        have_stderr(/Cannot start server on blabla\:5000\./)
    end

    it "checks if an IP-Address can be used for the web server binding" do
      # use the suse.com ip address for test
      cmd = "#{machinery_command} serve --ip 130.57.5.70 --port 5000 opensuse131"
      expect(@machinery.run_command(cmd)).to fail.and have_stderr(
        /The IP\-Address 130\.57\.5\.70 is not available\. Please choose a different IP\-Address\./
      )
    end

    it "tests the output when we use ports which needs root privileges" do
      cmd = "#{machinery_command} serve --ip 127.0.0.1 --port 1023 opensuse131"
      expect(@machinery.run_command(cmd)).to fail.and \
        have_stderr(/You need root privileges for ports between 1 and 1023!/)
    end
  end
end
