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

require_relative "spec_helper"

describe Autoyast do
  capture_machinery_output
  initialize_system_description_factory_store

  let(:expected_profile) {
    File.read(File.join(Machinery::ROOT, "spec/data/autoyast/simple.xml"))
  }
  let(:description) {
    create_test_description(
      store_on_disk: true,
      extracted_scopes: [
        "config_files",
        "changed_managed_files",
        "unmanaged_files"
      ],
      scopes: [
        "packages",
        "patterns",
        "repositories",
        "users_with_passwords",
        "groups",
        "services"
      ]
    )
  }

  describe "#profile" do
    it "handles quotes in changed links" do
      description["changed_managed_files"]["files"] <<
        ChangedManagedFile.new(
          name: "/opt/test-quote-char/link",
          package_name: "test-data-files",
          package_version: "1.0",
          status: "changed",
          changes: ["link_path"],
          mode: "777",
          user: "root",
          group: "root",
          type: "link",
          target: "/opt/test-quote-char/target-with-quote'-foo"
        )
      autoyast = Autoyast.new(description)

      expect(autoyast.profile).to include(
        "ln -s '/opt/test-quote-char/target-with-quote'\\\''-foo' '/mnt/opt/test-quote-char/link'"
      )
    end

    it "creates the expected profile" do
      autoyast = Autoyast.new(description)

      expect(autoyast.profile).to eq(expected_profile)
    end

    it "does not ask for export URL if files weren't extracted" do
      [
        "config_files",
        "changed_managed_files",
        "unmanaged_files"
      ].each do |scope|
        description[scope].extracted = false
      end
      autoyast = Autoyast.new(description)

      expect(autoyast.profile).not_to include("Enter URL to system description")
    end
  end

  describe "#write" do
    let(:ip) { "192.168.0.35" }
    before(:each) do
      autoyast = Autoyast.new(description)
      @output_dir = given_directory
      allow(autoyast).to receive(:outgoing_ip).and_return(ip)
      autoyast.write(@output_dir)
      expect(captured_machinery_output).to include(
        "Note: The permssions of the AutoYaST directory are restricted to be only" \
          " accessible by the current user. Further instructions are provided by the " \
          "README.md in the exported directory."
      )
    end

    it "copies over the system description" do
      expect(File.exists?(File.join(@output_dir, "manifest.json"))).to be(true)
    end

    it "adds the autoinst.xml" do
      expect(File.exists?(File.join(@output_dir, "autoinst.xml"))).to be(true)
    end

    it "adds unmanaged files filter list" do
      expect(File.exists?(File.join(@output_dir, "unmanaged_files_autoyast_excludes"))).to be(true)
    end

    it "filters log files from the Autoyast export" do
      expect(File.read(File.join(@output_dir, "unmanaged_files_autoyast_excludes"))).
        to include("var/log/*")
    end

    it "adds the autoyast export readme" do
      expect(File.exists?(File.join(@output_dir, "README.md"))).to be(true)
    end

    it "adds the ip of the outgoing network to the readme" do
      file = File.read(File.join(@output_dir, "README.md"))
      expect(file).to include("autoyast=http://#{ip}:8000/autoinst.xml")
      expect(file).to include("autoyast2=http://#{ip}:8000/autoinst.xml")
    end

    it "adds the autoyast export path to the readme" do
      file = File.read(File.join(@output_dir, "README.md"))
      expect(file).to include("cd #{@output_dir}; python -m SimpleHTTPServer")
      expect(file).to include("chmod -R a+rX #{@output_dir}")
    end

    it "restricts permissions of all exported files and dirs to the user" do
      Dir.glob(File.join(@output_dir, "/*")).each do |entry|
        next if entry.end_with?("/README.md")
        if File.directory?(entry)
          expect(File.stat(entry).mode & 0777).to eq(0700), entry
        else
          expect(File.stat(entry).mode & 0777).to eq(0600), entry
        end
      end
    end
  end

  describe "#export_name" do
    it "returns the export name" do
      autoyast = Autoyast.new(description)

      expect(autoyast.export_name).to eq("description-autoyast")
    end
  end

  describe "#outgoing_ip" do
    let(:autoyast) { Autoyast.new(description) }
    let(:ip_route) {
      "8.8.8.8 via 10.100.255.254 dev em1  src 10.100.2.35 \n    cache "
    }
    let(:ip_no_route) { "RTNETLINK answers: Network is unreachable " }

    it "returns the current outgoing ip" do
      expect(Cheetah).to receive(:run).with(
        "ip", "route", "get", "8.8.8.8", stdout: :capture
      ).and_return(ip_route)
      expect(autoyast.outgoing_ip).to eq("10.100.2.35")
    end

    it "returns ip placeholder if no external route exists" do
      expect(Cheetah).to receive(:run).with(
        "ip", "route", "get", "8.8.8.8", stdout: :capture
      ).and_return(ip_no_route)
      expect(autoyast.outgoing_ip).to eq("<ip>")
    end
  end
end
