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

describe Machinery::DpkgDatabase do
  let(:system) { Machinery::LocalSystem.new }
  let(:changed_files_result) {
    File.read(File.join(Machinery::ROOT, "spec/data/dpkg_managed_files_database/dpkg_--verify"))
  }
  let(:dpkg_result) {
    File.read(File.join(Machinery::ROOT, "spec/data/dpkg_managed_files_database/dpkg_-s_sudo"))
  }
  subject { Machinery::DpkgDatabase.new(system) }

  before(:each) do |test|
    unless test.metadata[:skip_before]
      allow(system).to receive(:has_command?).with("rpm").and_return(false)
      allow(system).to receive(:run_command).with("dpkg", "-S", any_args).and_return(
        "sudo: /etc/sudoers"
      )
      allow(system).to receive(:run_command).with("dpkg", "-s", any_args).and_return(
        dpkg_result
      )
      allow(system).to receive(:run_command).with("stat", any_args).and_return(
        File.read(File.join(Machinery::ROOT, "spec/data/dpkg_managed_files_database/stat"))
      )
      allow(system).to receive(:run_command).with("find", any_args).and_return(
        "/link_target"
      )
    end
  end

  describe "#managed_files_list" do
    it "returns the output of dpkg --verify" do
      expect(system).to receive(:run_command_with_progress).and_return(changed_files_result)

      expect(subject.managed_files_list).to eq(changed_files_result)
    end
  end

  describe "#package_for_file_path" do
    it "returns package name and version for a given file path" do
      allow(system).to receive(:run_command).with("dpkg", "-S", any_args).and_return(
        "sudo: /etc/sudoers"
      )
      allow(system).to receive(:run_command).with("dpkg", "-s", any_args).and_return(
        dpkg_result
      )

      package_name, package_version = subject.package_for_file_path("/etc/sudo")
      expect(package_name).to eq("sudo")
      expect(package_version).to eq("1.8.9p5-1ubuntu1.1")
    end

    it "can handle diversions" do
      dpkg_file_output = <<-EOF
diversion by branding-ubuntu from: /usr/share/gnome-mahjongg/themes/postmodern.svg
diversion by branding-ubuntu to: /usr/share/gnome-mahjongg/themes/postmodern.svg.unbranded
gnome-mahjongg, branding-ubuntu: /usr/share/gnome-mahjongg/themes/postmodern.svg
EOF
      dpkg_details_output = <<-EOF
Package: gnome-mahjongg
Status: install ok installed
Priority: optional
Section: games
Installed-Size: 3700
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Architecture: amd64
Version: 1:3.18.0-1
Replaces: mahjongg (<< 1:3.7.2)
Depends: libc6 (>= 2.4), libcairo2 (>= 1.2.4), libgdk-pixbuf2.0-0 (>= 2.22.0), libglib2.0-0 (>= 2.39.90), libgtk-3-0 (>= 3.13.2), librsvg2-2 (>= 2.32.0), dconf-gsettings-backend | gsettings-backend
Recommends: yelp
Breaks: mahjongg (<< 1:3.7.2)
Description: classic Eastern tile game for GNOME
 This is a solitaire (one player) version of the classic Eastern tile
 game, Mahjongg.
 .
 You start with five levels of tiles which are stacked so some are
 covered up by the tiles on top. The object of Mahjongg is to remove all
 the tiles from the game, by finding matching pairs which look alike.
Original-Maintainer: Debian GNOME Maintainers <pkg-gnome-maintainers@lists.alioth.debian.org>
Homepage: https://wiki.gnome.org/Apps/Mahjongg
EOF
      expect(system).to receive(:run_command).with(
        "dpkg", "-S", "/usr/share/gnome-mahjongg/themes/postmodern.svg", any_args
      ).and_return(dpkg_file_output)
      expect(system).to receive(:run_command).with(
        "dpkg", "-s", "gnome-mahjongg", any_args
      ).and_return(dpkg_details_output)
      package_name, _package_version = subject.package_for_file_path(
        "/usr/share/gnome-mahjongg/themes/postmodern.svg"
      )
      expect(package_name).to eq("gnome-mahjongg")
    end
  end

  describe "#parse_changes_line" do
    it "checks if a file was deleted although it was reported as changed by dpkg" do
      expect(system).to receive(:run_command).with("ls", "/etc/sudoers").
        and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))

      _file, changes, _type = subject.parse_changes_line("??5?????? c /etc/sudoers")
      expect(changes).to match_array(["deleted"])
    end
  end

  it "checks the requirements on the system", :skip_before do
    expect(system).to receive(:check_requirement).with("dpkg", "--version")
    expect(system).to receive(:check_requirement).with("stat", "--version")
    expect(system).to receive(:check_requirement).with("find", "--version")

    expect(subject).to receive(:managed_files_list).and_return("")

    subject.changed_files
  end

  it "caches the result" do
    expect(subject).to receive(:managed_files_list).and_return(changed_files_result).once
    allow(system).to receive(:run_command).with("ls", any_args)

    subject.changed_files
    subject.changed_files
  end

end
