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

require "given_filesystem/spec_helpers"
require File.expand_path("../../../tools/helper_builder", __FILE__)

describe HelperBuilder do
  include GivenFilesystemSpecHelpers
  use_given_filesystem

  let(:helper_dir) { given_directory("machinery/machinery-helper") }
  subject { HelperBuilder.new(helper_dir) }

  before(:each) do
    allow(subject).to receive(:puts)
    allow(STDERR).to receive(:puts)
  end

  describe "#run_build" do
    let(:commit) { "5e56e5a31b75d265fe7eba7194fea0a453e6660c" }

    before(:each) do
      allow(subject).to receive(:git_revision).and_return(commit)
      allow(subject).to receive(:run_uname_p).and_return("x86_64")
      allow(subject).to receive(:run_go_build).and_return(true)
      allow(subject).to receive(:run_which_go).and_return(true)
      allow(subject).to receive(:go_available?).and_return(true)
    end

    it "returns true if all commands succeed" do
      expect(subject.run_build).to be(true)
    end

    context "if architecture is unsupported" do
      before(:each) do
        expect(subject).to receive(:run_uname_p).and_return("unknown")
      end

      it "returns true" do
        expect(subject.run_build).to be(true)
      end

      it "does not build" do
        expect(subject).not_to receive(:run_go_build)
        subject.run_build
      end

      it "does not check for go_availbility" do
        expect(subject).not_to receive(:go_available?)
        subject.run_build
      end
    end

    context "if go environment unavailable" do
      before(:each) do
        expect(subject).to receive(:go_available?).and_return(false)
      end

      it "returns false" do
        expect(subject.run_build).to be(false)
      end

      it "does not build" do
        expect(subject).not_to receive(:run_go_build)
        subject.run_build
      end
    end

    context "if run in git and revision has changed" do
      before(:each) do
        allow(subject).to receive(:runs_in_git?).and_return(true)
      end

      it "returns false if build fails" do
        expect(subject).to receive(:run_go_build).and_return(false)
        expect(subject.run_build).to be(false)
      end

      it "writes go version file" do
        version_file = File.join(helper_dir, "version.go")
        expect(File.exist?(version_file)).to be(false)
        expect(subject.run_build).to be(true)
        expect(File.exist?(version_file)).to be(true)
      end

      it "creates version.go if it got removed but .git_revision still exist" do
        version_file = File.join(helper_dir, "version.go")
        git_revision_file = File.join(helper_dir, "..", ".git_revision")
        subject.write_git_revision_file
        expect(File.exist?(git_revision_file)).to be(true)
        expect(File.exist?(version_file)).to be(false)
        expect(subject.run_build).to be(true)
        expect(File.exist?(version_file)).to be(true)
      end

      it "creates git revision file after successful build" do
        git_revision_file = File.join(helper_dir, "..", ".git_revision")
        expect(File.exist?(git_revision_file)).to be(false)
        expect(subject).to receive(:run_go_build).and_return(true)
        expect(subject.run_build).to be(true)
        expect(File.exist?(git_revision_file)).to be(true)
      end

      it "does not create git revision file after failed build" do
        git_revision_file = File.join(helper_dir, "..", ".git_revision")
        expect(subject).to receive(:run_go_build).and_return(false)
        expect(subject.run_build).to be(false)
        expect(File.exist?(git_revision_file)).to be(false)
      end
    end

    context "if run in git and revision hasn't changed" do
      before(:each) do
        allow(subject).to receive(:runs_in_git?).and_return(true)
        # git revision file is compared to current GIT head
        subject.write_git_revision_file
      end

      it "returns false if build fails" do
        expect(subject).to receive(:run_go_build).and_return(false)
        expect(subject.run_build).to be(false)
      end

      it "builds go binary if source files are newer than binary" do
        FileUtils.touch(File.join(helper_dir, "machinery-helper"), mtime: Time.now.to_i - 10)
        FileUtils.touch(File.join(helper_dir, "machinery_helper.go"))
        expect(subject).to receive(:run_go_build).and_return(true)
        expect(subject.run_build).to be(true)
      end

      it "does not build go binary if source files are older than binary" do
        FileUtils.touch(File.join(helper_dir, "machinery-helper"))
        FileUtils.touch(File.join(helper_dir, "machinery_helper.go"), mtime: Time.now.to_i - 10)
        FileUtils.touch(File.join(helper_dir, "version.go"), mtime: Time.now.to_i - 10)
        expect(subject).not_to receive(:run_go_build)
        expect(subject.run_build).to be(true)
      end
    end

    context "if run outside of git" do
      before(:each) do
        allow(subject).to receive(:runs_in_git?).and_return(false)
      end

      it "returns false if build fails" do
        expect(subject).to receive(:run_go_build).and_return(false)
        expect(subject.run_build).to be(false)
      end

      it "does not create go version file" do
        version_file = File.join(helper_dir, "version.go")
        expect(subject.run_build).to be(true)
        expect(File.exist?(version_file)).to be(false)
      end

      it "does not create git revision file after successful build" do
        git_revision_file = File.join(helper_dir, "..", ".git_revision")
        expect(subject).to receive(:run_go_build).and_return(true)
        expect(subject.run_build).to be(true)
        expect(File.exist?(git_revision_file)).to be(false)
      end

      it "builds go binary if source files are newer than binary" do
        FileUtils.touch(File.join(helper_dir, "machinery-helper"), mtime: Time.now.to_i - 10)
        FileUtils.touch(File.join(helper_dir, "machinery_helper.go"))
        expect(subject).to receive(:run_go_build).and_return(true)
        expect(subject.run_build).to be(true)
      end

      it "does not build go binary if source files are older than binary" do
        FileUtils.touch(File.join(helper_dir, "machinery-helper"))
        FileUtils.touch(File.join(helper_dir, "machinery_helper.go"), mtime: Time.now.to_i - 10)
        expect(subject).not_to receive(:run_go_build)
        expect(subject.run_build).to be(true)
      end
    end
  end

  describe "#write_go_version_file" do
    let(:version_file) { File.join(helper_dir, "version.go") }

    it "it creates a version.go file" do
      expect(File.exist?(version_file)).to be(false)
      subject.write_go_version_file
      expect(File.exist?(version_file)).to be(true)
    end

    it "stores the current git revision as version in version.go" do
      git_revision = "5e56e5a31b75d265fe7eba7194fea0a453e6660c"
      allow(subject).to receive(:git_revision).and_return(git_revision)
      subject.write_go_version_file
      expect(File.read(version_file)).to include(
        "package main\n\nconst VERSION = \"#{git_revision}\""
      )
    end
  end

  describe "#build_machinery_helper" do
    it "changes to the helper directory" do
      expect(Dir).to receive(:chdir).with(helper_dir)
      subject.build_machinery_helper
    end

    context "if build succedes" do
      before(:each) do
        expect(subject).to receive(:run_go_build).and_return(true)
      end

      it "returns true" do
        expect(subject.build_machinery_helper).to be(true)
      end

      it "shows a building message on stdout" do
        expect(subject).to receive(:puts).with(
          "Building machinery-helper binary."
        )
        subject.build_machinery_helper
      end
    end

    context "if build fails" do
      before(:each) do
        expect(subject).to receive(:run_go_build).and_return(false)
      end

      it "returns false" do
        expect(subject.build_machinery_helper).to be(false)
      end

      it "shows warning" do
        expect(STDERR).to receive(:puts).with(
          "Warning: Building of the machinery-helper failed!"
        )
        subject.build_machinery_helper
      end

      it "removes the pre-existing machinery-helper binary" do
        machinery_helper = File.join(helper_dir, "machinery-helper")
        FileUtils.touch(machinery_helper)

        expect(File.exist?(machinery_helper)).to be(true)
        subject.build_machinery_helper
        expect(File.exist?(machinery_helper)).to be(false)
      end
    end
  end

  describe "#go_available?" do
    it "returns true if go is available according to which" do
      expect(subject).to receive(:run_which_go).and_return(true)
      expect(subject.go_available?).to be(true)
    end

    context "if go is not available according to which" do
      before(:each) do
        expect(subject).to receive(:run_which_go).and_return(false)
      end

      it "returns false" do
        expect(subject.go_available?).to be(false)
      end

      it "shows warning" do
        expect(STDERR).to receive(:puts).with(
          "Warning: The Go compiler is not available on this system. Skipping building the" \
            " machinery-helper.\nThe machinery-helper increases the inspection speed significantly."
        )
        subject.go_available?
      end
    end
  end

  describe "#arch_supported?" do
    it "returns true if the current architecture is in the supported list" do
      expect(subject).to receive(:run_uname_p).and_return("x86_64")
      expect(subject.arch_supported?).to be(true)
    end

    context "if current architecture is not supported" do
      before(:each) do
        expect(subject).to receive(:run_uname_p).and_return("arch")
      end

      it "returns false" do
        expect(subject.arch_supported?).to be(false)
      end

      it "shows a warning if the current architecture is not in the supported list" do
        expect(STDERR).to receive(:puts).with(
          "Warning: The hardware architecture arch is not yet supported by the machinery-helper."
        )
        subject.arch_supported?
      end
    end
  end

  describe "#runs_in_git?" do
    it "it returns true if the parent-directory of helper consists .git" do
      FileUtils.mkdir_p(File.join(helper_dir, "..", ".git"))
      expect(subject.runs_in_git?).to be(true)
    end

    it "it returns false if the parent-directory of helper does not consist .git" do
      expect(subject.runs_in_git?).to be(false)
    end
  end

  describe "#write_git_revision_file" do
    let(:git_revision_file) { File.join(helper_dir, "..", ".git_revision") }
    let(:commit) { "5e56e5a31b75d265fe7eba7194fea0a453e6660c" }

    before(:each) do
      expect(subject).to receive(:git_revision).and_return(commit)
    end

    it "writes the file .git_revision to the machinery directory" do
      expect(File.exist?(git_revision_file)).to be(false)
      subject.write_git_revision_file
      expect(File.exist?(git_revision_file)).to be(true)
    end

    it "stores the current git revision in the .git_revision file" do
      subject.write_git_revision_file
      expect(File.read(git_revision_file)).to eq(commit)
    end
  end

  describe "#changed_revision?" do
    let(:git_revision_file) { File.join(helper_dir, "..", ".git_revision") }
    let(:commit) { "5e56e5a31b75d265fe7eba7194fea0a453e6660c" }

    before(:each) do
      expect(subject).to receive(:git_revision).and_return(commit)
    end

    it "returns false if the content of .git_revision matches the current revision" do
      File.write(git_revision_file, commit)
      expect(subject.changed_revision?).to be(false)
    end

    it "returns true if the content of .git_revision does not match the current revision" do
      File.write(git_revision_file, "00638883ce526de0479be5125eb789a288418bf5")
      expect(subject.changed_revision?).to be(true)
    end

    it "returns true if the .git_revision does not exist" do
      expect(File.exist?(git_revision_file)).to be(false)
      expect(subject.changed_revision?).to be(true)
    end
  end
end
