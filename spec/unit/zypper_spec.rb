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

require_relative "spec_helper"

describe Zypper do
  subject { Zypper.new }

  describe ".isolated" do
    it "calls zypper in a chroot environment" do
      expect(Zypper).to receive(:cleanup)

      Zypper.isolated do |zypper|
        allow(LoggedCheetah).to receive(:run)
        expect(LoggedCheetah).to receive(:run) do |*args|
          expect(args).to include("--root")
          expect(args).to include("refresh")
        end

        zypper.refresh
      end
    end

    it "sets architecture in config file" do
      Zypper.isolated(arch: :ppc64le) do |zypper|
        expect(File.readlines(zypper.zypp_config)).to include("arch=ppc64le")
      end
    end

    it "sets a ZYPP_CONF environment variable" do
      Zypper.isolated(arch: :ppc64le) do |zypper|
        allow(LoggedCheetah).to receive(:run)
        expect(LoggedCheetah).to receive(:run) do |*args|
          expect(ENV.include?("ZYPP_CONF")).to be true
          expect(ENV.fetch("ZYPP_CONF")).to eq(zypper.zypp_config)
        end

        zypper.refresh
      end
    end
  end

  describe "#download_package" do
    it "download the package and returns the path on disk" do
      zypper_xml = <<-EOF
          <?xml version='1.0'?>
          <stream>
          <message type="info">Daten des Repositories laden ...</message>
          <message type="info">Installierte Pakete lesen ...</message>
          <progress id="" name="(1/1) /var/cache/machinery/zypp/packages/SMT-http_example_com:SLES11-SP3-Updates/rpm/x86_64/fontconfig-2.6.0-10.17.1.x86_64.rpm"/>
          <download-result><solvable><kind>package</kind><name>fontconfig</name><edition epoch="0" version="2.6.0" release="10.17.1"/><arch>x86_64</arch><repository name="SMT-http_example_com:SLES11-SP3-Updates" alias="SMT-http_example_com:SLES11-SP3-Updates"/></solvable><localfile path="/var/cache/machinery/zypp/packages/SMT-http_example_com:SLES11-SP3-Updates/rpm/x86_64/fontconfig-2.6.0-10.17.1.x86_64.rpm"/></download-result><progress id="" name="(1/1) /var/cache/machinery/zypp/packages/SMT-http_example_com:SLES11-SP3-Updates/rpm/x86_64/fontconfig-2.6.0-10.17.1.x86_64.rpm" done="0"/>

          <message type="info">Fertig.</message>
          </stream>
      EOF

      expect(subject).to receive(:call_zypper).with("-x", "download", anything(), anything()).
        and_return(zypper_xml)

      path = subject.download_package("fontconfig-2.6.0")

      expect(path).to eq("/var/cache/machinery/zypp/packages/SMT-http_example_com:SLES11-SP3-Updates/rpm/x86_64/fontconfig-2.6.0-10.17.1.x86_64.rpm")
    end
  end
end
