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

require_relative "../../tools/go"

describe Go do
  describe "#archs" do
    before(:each) do
      allow(subject).to receive(:suse_package_includes_s390?).and_return(false)
    end

    context "for go 1.4 or older" do
      before(:each) do
        allow(subject).to receive(:version).and_return(1.4)
      end

      context "if arch is an x86 one" do
        it "returns local arch for x86_64" do
          allow(subject).to receive(:local_arch).and_return("x86_64")
          expect(subject.archs).to eq(["x86_64"])
        end

        it "returns local arch for i686" do
          allow(subject).to receive(:local_arch).and_return("i686")
          expect(subject.archs).to eq(["i686"])
        end
      end

      it "returns empty list if local arch is not an x86 one" do
        allow(subject).to receive(:version).and_return(1.4)
        allow(subject).to receive(:local_arch).and_return("s390x")
        expect(subject.archs).to eq([])
      end
    end

    context "for go 1.5 and 1.6 upstream" do
      it "returns arm, x86_64, i686 and ppc64le" do
        allow(subject).to receive(:version).and_return(1.6)
        expect(subject.archs).to match_array(
          ["x86_64", "i686", "ppc64le", "ppc64", "armv6l", "armv7l", "aarch64"]
        )
      end
    end

    context "for go-s390x 1.6 (machinery build)" do
      it "returns arm, x86_64, i686, ppc64le, ppc64 and s390x" do
        allow(subject).to receive(:version).and_return(1.6)
        allow(subject).to receive(:suse_package_includes_s390?).and_return(true)

        expect(subject.archs).to match_array(
          ["x86_64", "i686", "ppc64le", "ppc64", "s390x", "armv6l", "armv7l", "aarch64"]
        )
      end
    end

    context "for go 1.7 and newer" do
      it "returns arm, x86_64, i686, ppc64le, ppc64 and s390x" do
        allow(subject).to receive(:version).and_return(1.7)
        expect(subject.archs).to match_array(
          ["x86_64", "i686", "ppc64le", "ppc64", "s390x", "armv6l", "armv7l", "aarch64"]
        )
      end
    end
  end

  describe "#build" do
    before(:each) do
      allow($stdout).to receive(:puts)
    end

    context "if only one architecture is supported" do
      it "runs a regular build" do
        expect(subject).to receive(:archs).and_return(["x86_64"]).at_least(:once)
        expect(subject).to receive(:system).with("go build -o machinery-helper-x86_64")
        subject.build
      end

      it "shows a build message" do
        expect(subject).to receive(:archs).and_return(["x86_64"]).at_least(:once)
        expect($stdout).to receive(:puts).with("Building machinery-helper for architecture x86_64.")
        allow(subject).to receive(:system).with("go build -o machinery-helper-x86_64")
        subject.build
      end
    end

    context "if more then one architecture is supported" do
      it "runs cross compilation for each architecture" do
        expect(subject).to receive(:archs).and_return(["x86_64", "i686", "ppc64le"]).at_least(:once)
        expect(subject).to receive(:system).with(
          "env GOOS=linux GOARCH=amd64 go build -o machinery-helper-x86_64"
        )
        expect(subject).to receive(:system).with(
          "env GOOS=linux GOARCH=386 GO386=387 go build -o machinery-helper-i686"
        )
        expect(subject).to receive(:system).with(
          "env GOOS=linux GOARCH=ppc64le go build -o machinery-helper-ppc64le"
        )
        subject.build
      end

      it "show a build message for each architecture" do
        expect(subject).to receive(:archs).and_return(["x86_64", "i686"]).at_least(:once)
        expect($stdout).to receive(:puts).with("Building machinery-helper for architecture x86_64.")
        allow(subject).to receive(:system).with(
          "env GOOS=linux GOARCH=amd64 go build -o machinery-helper-x86_64"
        )
        expect($stdout).to receive(:puts).with("Building machinery-helper for architecture i686.")
        allow(subject).to receive(:system).with(
          "env GOOS=linux GOARCH=386 GO386=387 go build -o machinery-helper-i686"
        )
        subject.build
      end

      it "compiles arm and i686 with the appropriate compiler options" do
        expect(subject).to receive(:archs).and_return(
          ["armv6l", "armv7l", "aarch64", "i686"]
        ).at_least(:once)
        expect(subject).to receive(:system).with(
          "env GOOS=linux GOARCH=arm GOARM=6 go build -o machinery-helper-armv6l"
        )
        expect(subject).to receive(:system).with(
          "env GOOS=linux GOARCH=arm GOARM=7 go build -o machinery-helper-armv7l"
        )
        expect(subject).to receive(:system).with(
          "env GOOS=linux GOARCH=arm64 go build -o machinery-helper-aarch64"
        )
        expect(subject).to receive(:system).with(
          "env GOOS=linux GOARCH=386 GO386=387 go build -o machinery-helper-i686"
        )
        subject.build
      end
    end
  end

  describe "#available?" do
    it "returns true if go is available according to which" do
      expect(subject).to receive(:run_which_go).and_return(true)
      expect(subject.available?).to be(true)
    end

    it "returns false if go is not available and shows a warning" do
      expect(subject).to receive(:run_which_go).and_return(false)
      expect(STDERR).to receive(:puts).with(
        "ERROR: The official Go compiler is not available on this system which prevents the" \
          " machinery-helper binaries from being built."
      )
      expect(subject.available?).to be(false)
    end
  end
end
