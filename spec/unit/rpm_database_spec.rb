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

describe Machinery::RpmDatabase do
  let(:system) { Machinery::LocalSystem.new }
  let(:changed_files_sh_result) {
    File.read(File.join(Machinery::ROOT,
      "spec/data/rpm_managed_files_database/changed_files_sh_result"))
  }
  subject { Machinery::RpmDatabase.new(system) }

  before(:each) do
    allow(system).to receive(:has_command?).with("rpm").and_return(true)
    allow(system).to receive(:run_command).with("rpm", any_args).and_return(
      "zypper-1.6.311-16.2.3.x86_64"
    )
    allow(system).to receive(:run_command).with("stat", any_args).and_return(
      File.read(File.join(Machinery::ROOT, "spec/data/rpm_managed_files_database/stat_result"))
    )
    allow(system).to receive(:run_command).with("find", any_args).and_return(
      "/link_target"
    )

  end

  describe "#managed_files_list" do
    it "returns the output of the helper script" do
      expect(system).to receive(:run_script_with_progress).and_return(changed_files_sh_result)

      expect(subject.managed_files_list).to eq(changed_files_sh_result)
    end
  end

  describe "#package_for_file_path" do
    it "returns package name and version for a given file path" do
      allow(system).to receive(:run_command).with("rpm", any_args).and_return(
        "zypper-1.6.311-16.2.3.x86_64"
      )
      package_name, package_version = subject.package_for_file_path("/usr/bin/zypper")
      expect(package_name).to eq("zypper")
      expect(package_version).to eq("1.6.311")

    end
  end

  it "checks the requirements on the system" do
    allow(subject).to receive(:managed_files_list).and_return("")
    expect(system).to receive(:check_requirement).with("rpm", "--version")
    expect(system).to receive(:check_requirement).with("stat", "--version")
    expect(system).to receive(:check_requirement).with("find", "--version")

    subject.changed_files
  end

  it "caches the result" do
    expect(subject).to receive(:managed_files_list).and_return(changed_files_sh_result).once

    subject.changed_files
    subject.changed_files
  end
end
