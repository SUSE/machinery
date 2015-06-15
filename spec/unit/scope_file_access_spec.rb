require_relative "spec_helper"

describe "ScopeFileAccess" do
  initialize_system_description_factory_store

  describe ScopeFileAccessFlat do
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
        expect { subject.write_file(link, "/tmp") }.to raise_error(Machinery::Errors::FileUtilsError)
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
  end

  describe ScopeFileAccessArchive do
    describe "#export_files_as_tarballs" do
      it "should copy all tarballs to the destination" do
        description = create_test_description(
          store_on_disk: true,
          extracted_scopes: ["unmanaged_files"]
        )

        target = given_directory
        description.unmanaged_files.export_files_as_tarballs(target)

        expect(File.exists?(File.join(target, "files.tgz"))).to be(true)
        expect(File.exists?(File.join(target, "trees/etc/tarball with spaces.tgz"))).to be(true)
      end
    end
  end
end
