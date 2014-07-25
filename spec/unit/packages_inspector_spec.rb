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

describe PackagesInspector, ".inspect" do
  let(:description) {
    SystemDescription.new("systemname", {}, SystemDescriptionStore.new)
  }
  let(:packages_inspector) { PackagesInspector.new }

  let(:package_example) { <<EOF
zypper|0.1.0$
rpm|0.4.2$
EOF
  }
  let(:rpm_command) {
    ["rpm", "-qa", "--qf", "%{NAME}|%{VERSION}$", :stdout=>:capture]
  }

  def inspect_data(host = "myhost", data = package_example)
    inspector = PackagesInspector.new
    system = System.for(host)

    expect(system).to receive(:run_command) { data }

    inspector.inspect(system, description)
    description.packages
  end

  it "returns a local SystemDescription containing rpm as one package" do
    expect(inspect_data.first.name).to eq("rpm")
  end

  it "returns a remote SystemDescription containing rpm as one package" do
    expect(inspect_data("remotehost", package_example).first.name).to eq("rpm")
  end

  it "ignores fake rpm packages with the name gpg-pubkey" do
    data = "gpg-pubkey|39db7c82$#{package_example}"
    expect(inspect_data("myhost", data).count).to eq(2)
  end

  it "returns a summary" do
    system = double
    expect(system).to receive(:check_requirement) { true }
    expect(system).to receive(:run_command) { package_example }

    summary = packages_inspector.inspect(system, description)
    expect(summary).to include("Found 2 packages")
  end

  it "returns sorted data" do
    names = inspect_data.map(&:name)
    expect(names).to eq(names.sort)
  end
end
