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
        file_content = description.config_files.file_content("/etc/crontab")
        expect(file_content).to eq("-*/15 * * * *   root  echo config_files_integration_test\n")
      end

      it "raises an error if file is not found" do
        expect {
          description.changed_managed_files.file_content("/does/not/exist")
        }.to raise_error(Machinery::Errors::FileUtilsError, /'\/does\/not\/exist' was not found/)
      end

      it "raises an error if the files were not extracted" do
        description = create_test_description(scopes: ["changed_managed_files"])
        expect {
          description.changed_managed_files.file_content("/etc/crontab")
        }.to raise_error(
          Machinery::Errors::FileUtilsError, /for scope 'changed_managed_files' were not extracted/
        )
      end
    end
  end

  describe ScopeFileAccessArchive do
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
        expect(File.exists?(File.join(scope_file_store.path, "files.tgz"))).to be(true)
      end

      it "create tree tarballs in the scope file store" do
        expect(system).to receive(:create_archive) do |_files, archive_path, _excluded|
          FileUtils.touch(archive_path)
        end.at_least(:once)

        subject.retrieve_trees_from_system_as_archive(system, ["/opt", "/foo/bar"], ["/exclude"])
        expect(File.exists?(File.join(scope_file_store.path, "trees", "opt.tgz"))).to be(true)
        expect(File.exists?(File.join(scope_file_store.path, "trees", "foo/bar.tgz"))).to be(true)
      end
    end

    describe "#file_content" do
      let(:description) {
        SystemDescription.load!("opensuse131-build",
          SystemDescriptionStore.new("spec/data/descriptions"))
      }

      it "returns the file content of a file stored in the files.tgz tar ball" do
        file_content = description.unmanaged_files.file_content("/etc/magicapp.conf")

        expect(file_content).to eq("This is magicapp.conf\n")
      end

      it "raises an error if file is not found" do
        expect {
          description.unmanaged_files.file_content("/does/not/exist")
        }.to raise_error(Machinery::Errors::FileUtilsError, /'\/does\/not\/exist' was not found/)
      end

      it "raises an error if the files were not extracted" do
        description = create_test_description(scopes: ["unmanaged_files"])
        expect {
          description.unmanaged_files.file_content("/etc/crontab")
        }.to raise_error(
          Machinery::Errors::FileUtilsError, /for scope 'unmanaged_files' were not extracted/
          )
      end
    end

    describe "#export_files_as_tarballs" do
      it "should copy all tarballs to the destination" do
        target = given_directory
        description.unmanaged_files.export_files_as_tarballs(target)

        expect(File.exists?(File.join(target, "files.tgz"))).to be(true)
        expect(File.exists?(File.join(target, "trees/etc/tarball with spaces.tgz"))).to be(true)
      end
    end
  end
end
