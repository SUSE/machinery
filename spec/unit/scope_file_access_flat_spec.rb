require_relative "spec_helper"

describe ScopeFileAccessFlat do
  initialize_system_description_factory_store
  let(:description) {
    create_test_description(
      store_on_disk: true,
      extracted_scopes: ["config_files"]
    )
  }
  subject { description.config_files }
  let(:dir) { subject.files.find(&:directory?) }
  let(:link) { subject.files.find(&:link?) }
  let(:file) { subject.files.find { |file| file.name == "/etc/cron tab" } }

  describe ".file_path" do
    it "raises an exception for non-files" do
      expect {
        subject.file_path(dir)
      }.to raise_error(Machinery::Errors::FileUtilsError)
    end

    it "returns the local path to the file" do
      expected = File.join(subject.scope_file_store.path, file.name)
      expect(subject.file_path(file)).to eq(expected)
    end
  end

  describe ".write_file" do
    it "raises an exception for non-files" do
      expect {
        subject.write_file(link, "/tmp")
      }.to raise_error(Machinery::Errors::FileUtilsError)
    end

    it "copies the file" do
      source_path = subject.file_path(file)
      FileUtils.mkdir_p(File.dirname(source_path))
      FileUtils.touch(source_path)

      target = given_directory
      subject.write_file(file, target)

      expect(File.exists?(File.join(target, file.name))).to be(true)
    end
  end

  describe "#file_content" do
    let(:description) {
      SystemDescription.load!("opensuse131-build",
        SystemDescriptionStore.new("spec/data/descriptions"))
    }

    it "returns the file content of a file stored in a directory" do
      system_file = description.config_files.files.find do |file|
        file.name == "/etc/crontab"
      end

      file_content = description.config_files.file_content(system_file)
      expect(file_content).to eq("-*/15 * * * *   root  echo config_files_integration_test\n")
    end

    it "raises an error if the files were not extracted" do
      description["changed_managed_files"].extracted = false
      system_file = description.config_files.files.find do |file|
        file.name == "/etc/crontab"
      end

      expect {
        description.changed_managed_files.file_content(system_file)
      }.to raise_error(
        Machinery::Errors::FileUtilsError, /for scope 'changed_managed_files' were not extracted/
      )
    end
  end

  describe "#binary?" do
    let(:description) {
      SystemDescription.load!("changed-managed-files-good",
        SystemDescriptionStore.new("spec/data/descriptions/validation"))
    }

    it "returns false if a file is a text file" do
      system_file = description.changed_managed_files.files.find do |file|
        file.name == "/lib/mkinitrd/scripts/setup-done.sh"
      end

      is_binary = description.changed_managed_files.binary?(system_file)
      expect(is_binary).to be(false)
    end

    it "returns true if a file is a binary file" do
      system_file = description.changed_managed_files.files.find do |file|
        file.name == "/lib/libc-2.19.so"
      end

      is_binary = description.changed_managed_files.binary?(system_file)
      expect(is_binary).to be(true)
    end

    it "returns false if the file is empty" do
      system_file = description.changed_managed_files.files.find do |file|
        file.name == "/lib/mkinitrd/scripts/empty.sh"
      end

      is_binary = description.changed_managed_files.binary?(system_file)
      expect(is_binary).to be(false)
    end

    it "tests an xml file if it is marked as binary or not" do
      system_file = description.changed_managed_files.files.find do |file|
        file.name == "/lib/mkinitrd/scripts/test.xml"
      end

      is_binary = description.changed_managed_files.binary?(system_file)
      expect(is_binary).to be(false)
    end
  end

  describe "#has_file?" do
    let(:description) {
      SystemDescription.load!("opensuse131-build",
        SystemDescriptionStore.new("spec/data/descriptions"))
    }

    it "returns true" do
      expect(description.config_files.has_file?("/etc/crontab")).to be_truthy
    end
  end
end
