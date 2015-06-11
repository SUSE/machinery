require_relative "spec_helper"

describe ScopeFileAccess do
  initialize_system_description_factory_store

  describe "#export_files_as_tarballs" do
    it "should copy all tarballs to the destination" do
      description = create_test_description(
        store_on_disk: true,
        extracted_scopes: ["unmanaged_files"]
      )

      target = given_directory
      description.unmanaged_files.file_access.export_files_as_tarballs(target)

      expect(File.exists?(File.join(target, "files.tgz"))).to be(true)
      expect(File.exists?(File.join(target, "trees/etc/tarball with spaces.tgz"))).to be(true)
    end
  end
end
