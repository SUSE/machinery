#  Copyright (c) 2013-2016 SUSE LLC
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
        curl_command = @machinery.run_command("curl http://127.0.0.1:#{port}/opensuse131")

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
      cmd = "#{machinery_command} serve --port 5000"
      Thread.new do
        @machinery.run_command(cmd)
      end

      test_basic_html(5000)

      # Test file content download
      expected_content = File.read(
        File.join(system_description_dir, "changed_config_files", "etc", "crontab")
      )
      curl_command = @machinery.run_command(
        "curl http://127.0.0.1:5000/descriptions/opensuse131/files/changed_config_files/etc/crontab"
      )
      expect(curl_command).to succeed.with_stderr.and have_stdout(expected_content)
    end

    it "prints a warning when --public is used" do
      cmd = "#{machinery_command} serve --port 5000 --public"
      res = nil
      Thread.new do
        res = @machinery.run_command(cmd, stderr: :capture)
      end

      test_basic_html(5000)

      @machinery.run_command("pkill -f 'machinery serve' --signal 15")

      # wait until the process quits and writes the response of the program
      # into 'res'
      times = 0
      while res.nil? && times < 10
        times += 1
        sleep(1)
      end

      expect(res.stderr).to include("--public")
    end

    it "does not print a warning when --public is not used" do
      cmd = "#{machinery_command} serve --port 5000"
      res = nil
      Thread.new do
        res = @machinery.run_command(cmd, stderr: :capture)
      end

      test_basic_html(5000)

      @machinery.run_command("pkill -f 'machinery serve' --signal 15")

      # wait until the process quits and writes the response of the program
      # into 'res'
      times = 0
      while res.nil? && times < 10
        times += 1
        sleep(1)
      end

      expect(res.stderr).to be_empty
    end

    it "makes the system description HTML available at the config-file port" do
      @machinery.run_command("MACHINERY_CONFIG_FILE=#{config_tmp_file} #{machinery_command} config http-server-port=7500")

      cmd = "#{machinery_command} serve"

      Thread.new do
        @machinery.run_command("MACHINERY_CONFIG_FILE=#{config_tmp_file} #{cmd}")
      end

      test_basic_html(7500)
      @machinery.run_command("rm -f '#{config_tmp_file}'")
    end

    it "makes sure a port can't be used twice" do
      cmd = "#{machinery_command} serve --port 5000"
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
  end
end
