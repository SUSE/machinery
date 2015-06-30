require_relative "spec_helper"

describe OdsFormatter do
  include GivenFilesystemSpecHelpers
  use_given_filesystem

  describe "#write" do
    let(:path) { given_directory_from_data "support_matrix" }
    let(:matrix) { SupportMatrix.new(path, subject) }

    it "creates an .ods file" do
      subject.write(matrix, path)

      expect(File.exist?(File.join(path, "Machinery_support_matrix.ods"))).to be(true)
    end
  end
end
