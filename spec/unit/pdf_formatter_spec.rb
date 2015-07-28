require_relative "spec_helper"

describe PdfFormatter do
  include GivenFilesystemSpecHelpers
  use_given_filesystem

  describe "#write" do
    let(:path) { given_directory_from_data "support_matrix" }
    let(:matrix) { SupportMatrix.new(path, subject) }

    it "creates an .pdf file" do
      # This line is just introduced because of an issue in the prawn gem
      # See: https://github.com/prawnpdf/prawn/issues/386
      expect(subject).to receive(:sections).and_return(true)

      subject.write(matrix, path)

      expect(File.exist?(File.join(path, "Machinery_support_matrix.pdf"))).to be(true)
    end
  end
end
