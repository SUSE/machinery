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

describe PackagesInspector, ".inspect" do
  let(:description) {
    SystemDescription.new("systemname", SystemDescriptionStore.new)
  }
  let(:filter) { nil }
  let(:packages_inspector) { PackagesInspector.new }

  let(:package_example) { <<EOF
zypper|1.9.16|22.2|x86_64|openSUSE|4a87f6b9ceae5d40a411fe52d0f17050$
rpm|4.11.1|6.5.1|x86_64|openSUSE|7dfdd742a9b7d60c75bf4844d294716d$
EOF
  }
  let(:expected_packages) {
    PackagesScope.new(
      [
        Package.new(
          name: "rpm",
          version: "4.11.1",
          release: "6.5.1",
          arch: "x86_64",
          vendor: "openSUSE",
          checksum: "7dfdd742a9b7d60c75bf4844d294716d"
        ),
        Package.new(
          name: "zypper",
          version: "1.9.16",
          release: "22.2",
          arch: "x86_64",
          vendor: "openSUSE",
          checksum: "4a87f6b9ceae5d40a411fe52d0f17050"
        )
      ]
    )
  }
  let(:rpm_command) {
    ["rpm", "-qa", "--qf", "%{NAME}|%{VERSION}|%{RELEASE}|%{ARCH}|%{VENDOR}|%{FILEMD5S}$", :stdout=>:capture]
  }

  def inspect_data(host = "myhost", data = package_example)
    inspector = PackagesInspector.new
    system = double(
      :requires_root?    => false,
      :host              => "example.com",
      :check_requirement => nil
    )

    expect(system).to receive(:run_command) { data }

    inspector.inspect(system, description, filter)
    description.packages
  end

  it "returns a local SystemDescription containing rpm as one package" do
    expect(inspect_data).to eq(expected_packages)
  end

  it "returns a remote SystemDescription containing rpm as one package" do
    expect(inspect_data("remotehost", package_example)).to eq(expected_packages)
  end

  it "ignores fake rpm packages with the name gpg-pubkey" do
    data = "gpg-pubkey|39db7c82|1.0$#{package_example}"
    expect(inspect_data(data)).to eq(expected_packages)
  end

  it "returns a summary" do
    system = double
    expect(system).to receive(:check_requirement) { true }
    expect(system).to receive(:run_command) { package_example }

    packages_inspector.inspect(system, description, filter)
    expect(packages_inspector.summary(description)).to include("Found 2 packages")
  end

  it "returns sorted data" do
    names = inspect_data.map(&:name)
    expect(names).to eq(names.sort)
  end
end
