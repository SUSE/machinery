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

describe Zypper do
  subject { Zypper.new }

  describe ".isolated" do
    let(:tmp_path) { Dir.mktmpdir("machinery_zypper") }
    let(:zypp_repo_path) { File.join(tmp_path, "/etc/zypp/repos.d/") }
    let(:base_url) { "http://download.opensuse.org/distribution/leap/42.2/repo/oss/" }

    before(:each) do
      allow(LoggedCheetah).to receive(:run).with(
        "sudo", "rm", "-rf", any_args
      )
      allow(LoggedCheetah).to receive(:run).with(
        "rm", "-rf", any_args
      )

      allow(Dir).to receive(:mktmpdir).with("machinery_zypper").and_return(tmp_path)

      FileUtils.mkdir_p(zypp_repo_path)
      file_content = <<-EOF
[repo-oss]
name=openSUSE-leap/42.2-Oss
enabled=1
autorefresh=1
baseurl=#{base_url}
path=/
type=yast2
EOF
      File.write(File.join(zypp_repo_path, "repo-oss.repo"), file_content)
    end

    after(:each) do
      if tmp_path.start_with?("/tmp/", "/var/tmp/")
        FileUtils.remove_dir(tmp_path)
      end
    end

    it "calls zypper in a chroot environment" do
      Zypper.isolated(arch: :x86_64) do |zypper|
        allow(LoggedCheetah).to receive(:run)
        expect(LoggedCheetah).to receive(:run) do |*args|
          expect(args).to include("--root")
          expect(args).to include("refresh")
        end

        zypper.refresh
      end
    end

    context "during zypper refresh" do
      context "with nfs repos" do
        let(:base_url) { "nfs://download.opensuse.org/distribution/leap/42.2/repo/oss/" }

        it "calls refresh with sudo" do
          Zypper.isolated(arch: :x86_64) do |zypper|
            allow(LoggedCheetah).to receive(:run)
            expect(LoggedCheetah).to receive(:run) do |*args|
              expect(args).to include("sudo", "refresh")
            end

            zypper.refresh
          end
        end

        it "cleans up with sudo" do
          expect(LoggedCheetah).to receive(:run).with(
            "sudo", "rm", "-rf", tmp_path
          )

          Zypper.isolated(arch: :x86_64) do |zypper|
            allow(LoggedCheetah).to receive(:run)
            zypper.refresh
          end
        end
      end

      context "with smb repos" do
        let(:base_url) { "smb://download.opensuse.org/distribution/leap/42.2/repo/oss/" }

        it "calls refresh with sudo" do
          Zypper.isolated(arch: :x86_64) do |zypper|
            allow(LoggedCheetah).to receive(:run)
            expect(LoggedCheetah).to receive(:run) do |*args|
              expect(args).to include("sudo", "refresh")
            end

            zypper.refresh
          end
        end

        it "cleans up with sudo" do
          expect(LoggedCheetah).to receive(:run).with(
            "sudo", "rm", "-rf", tmp_path
          )

          Zypper.isolated(arch: :x86_64) do |zypper|
            allow(LoggedCheetah).to receive(:run)
            zypper.refresh
          end
        end
      end

      context "without nfs repos" do
        it "calls refresh without sudo" do
          Zypper.isolated(arch: :x86_64) do |zypper|
            allow(LoggedCheetah).to receive(:run)
            expect(LoggedCheetah).to receive(:run) do |*args|
              expect(args).not_to include("sudo")
              expect(args).to include("refresh")
            end

            zypper.refresh
          end
        end

        it "cleans up without sudo" do
          expect(LoggedCheetah).to receive(:run).with(
            "rm", "-rf", tmp_path
          )

          Zypper.isolated(arch: :x86_64) do |zypper|
            allow(LoggedCheetah).to receive(:run)
            zypper.refresh
          end
        end
      end
    end

    context "in case of non-default tmp directories" do
      let(:tmp_path) { "/var/tmp/machinery_zypper/" }

      it "raises before cleaning up" do
        expect(LoggedCheetah).not_to receive(:run).with(
          "sudo", "rm", "-rf", tmp_path
        )
        expect do
          Zypper.isolated(arch: :x86_64) do |zypper|
            allow(LoggedCheetah).to receive(:run)
            zypper.refresh
          end
        end.to raise_error
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

      expect(subject).to receive(:call_zypper).with("-x", "download", anything, anything).
        and_return(zypper_xml)

      path = subject.download_package("fontconfig-2.6.0")

      expect(path).to eq("/var/cache/machinery/zypp/packages/SMT-http_example_com:SLES11-SP3-Updates/rpm/x86_64/fontconfig-2.6.0-10.17.1.x86_64.rpm")
    end

    it "can handle xml output in case of unavailable packages" do
      zypper_xml = <<-EOF
<?xml version='1.0'?>
<stream>
<message type="info">Loading repository data...</message>
<message type="info">Reading installed packages...</message>
<message type="warning">Argument resolves to no package: test-data-files-1.0</message>
<message type="info">Nothing to do.</message>
<message type="info">download: Done.</message>
</stream>
      EOF
      expect(subject).to receive(:call_zypper).and_return(zypper_xml)
      expect { subject.download_package("test-data-files-1.0") }.not_to raise_error
    end
  end
end
