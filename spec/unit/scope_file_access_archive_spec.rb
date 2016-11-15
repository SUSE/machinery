require_relative "spec_helper"

describe Machinery::ScopeFileAccessArchive do
  initialize_system_description_factory_store
  let(:description) {
    create_test_description(
      store_on_disk: true,
      extracted_scopes: ["unmanaged_files"]
    )
  }
  let(:system) { double }
  let(:scope_file_store) { subject.scope_file_store }
  subject { description.unmanaged_files }

  describe "retrieve_files_from_system_as_archive" do
    it "creates a files tarball in the scope file store" do
      expect(system).to receive(:create_archive) do |_files, archive_path, _excluded|
        FileUtils.touch(archive_path)
      end

      subject.retrieve_files_from_system_as_archive(system, ["/foo", "/bar"], ["/exclude"])
      expect(File.exist?(File.join(scope_file_store.path, "files.tgz"))).to be(true)
    end

    it "create tree tarballs in the scope file store" do
      expect(system).to receive(:create_archive) do |_files, archive_path, _excluded|
        FileUtils.touch(archive_path)
      end.at_least(:once)

      subject.retrieve_trees_from_system_as_archive(system, ["/opt", "/foo/bar"], ["/exclude"])
      expect(File.exist?(File.join(scope_file_store.path, "trees", "opt.tgz"))).to be(true)
      expect(File.exist?(File.join(scope_file_store.path, "trees", "foo/bar.tgz"))).to be(true)
    end
  end

  describe "#file_content" do
    let(:description) {
      Machinery::SystemDescription.load!("opensuse_leap-build",
        Machinery::SystemDescriptionStore.new("spec/data/descriptions"))
    }

    it "returns the file content of a file stored in the files.tgz tar ball" do
      system_file = description.unmanaged_files.find do |file|
        file.name == "/etc/magicapp.conf"
      end
      file_content = description.unmanaged_files.file_content(system_file)

      expect(file_content).to eq("This is magicapp.conf\n")
    end
  end

  describe "#has_file?" do
    let(:description) {
      Machinery::SystemDescription.load!("opensuse_leap-build",
        Machinery::SystemDescriptionStore.new("spec/data/descriptions"))
    }

    context "when the description keeps track of the file" do
      it "returns true" do
        expect(description.unmanaged_files.has_file?("/etc/magicapp.conf")).to be_truthy
      end
    end

    context "when file is hidden inside a tarball" do
      it "returns true" do
        expect(description.unmanaged_files.has_file?("/usr/local/magicapp/one")).to be_truthy
      end
    end

    context "in any other case" do
      it "returns false" do
        expect(description.unmanaged_files.has_file?("/foo/bar/file.txt")).to be_falsy
      end
    end
  end

  describe "#export_files_as_tarballs" do
    it "should copy all tarballs to the destination" do
      target = given_directory
      description.unmanaged_files.export_files_as_tarballs(target)

      expect(File.exist?(File.join(target, "files.tgz"))).to be(true)
      expect(File.exist?(File.join(target, "trees/etc/tarball with spaces.tgz"))).to be(true)
    end
  end

  describe "#binary?" do
    let(:description) {
      Machinery::SystemDescription.load!("unmanaged-files-good",
        Machinery::SystemDescriptionStore.new("spec/data/descriptions/validation"))
    }

    it "returns false if a file is a text file" do
      system_file = description.unmanaged_files.find do |file|
        file.name == "/etc/grub.conf"
      end

      is_binary = description.unmanaged_files.binary?(system_file)
      expect(is_binary).to be(false)
    end

    it "returns true if a file is a binary file" do
      system_file = description.unmanaged_files.find do |file|
        file.name == "/var/lib/misc/random-seed"
      end

      is_binary = description.unmanaged_files.binary?(system_file)
      expect(is_binary).to be(true)
    end

    it "returns false if the file is empty" do
      system_file = description.unmanaged_files.find do |file|
        file.name == "/root/.bash_history"
      end

      is_binary = description.unmanaged_files.binary?(system_file)
      expect(is_binary).to be(false)
    end
  end
end
