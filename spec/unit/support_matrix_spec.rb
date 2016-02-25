require_relative "spec_helper"

describe SupportMatrix do
  include GivenFilesystemSpecHelpers
  use_given_filesystem

  subject { SupportMatrix.new(path, formatter) }
  let(:path) { given_directory_from_data "support_matrix" }
  let(:target_path) { given_directory }
  let(:formatter) { PdfFormatter.new }

  describe "#new" do
    it "converts the path to an array" do
      expect(subject.path).to be_an(Array)
    end
  end

  describe "#write" do
    it "creates a .pdf file" do
      subject.write(target_path)

      expect(File.exist?(File.join(target_path, "Machinery_support_matrix.pdf"))).to be(true)
    end
  end

  describe "#integration_tests" do
    it "returns a hash with the integration tests" do
      expect(
        subject.integration_tests["inspect"]["supported"]["sles12:x86_64"]["sles12:x86_64"]
      ).to eq("full_test")
    end
  end

  describe "#unit_tests" do
    it "returns a hash with the unit tests" do
      unit_tests = {
        "running" => { "sles12:x86_64" => nil, "sles12:s390x" => nil, "sles12:power_le" => nil },
        "tested" => { "openSUSE_13_1:x86_64" => "ruby2.0", "openSUSE_13_2:x86_64" => "ruby2.1" }
      }
      expect(subject.unit_tests).to eq(unit_tests)
    end
  end

  describe "#runs_on" do
    it "returns a hash with the runs on information" do
      expect(
        subject.runs_on["supported"]["sles12:x86_64"]["Package installation"]
      ).to eq("full_test")
    end
  end

  describe "#integration_tests_cols" do
    it "returns a hash containing all columns" do
      expected_cols = {
        "openSUSE_13_2" => ["x86_64"],
        "openSUSE_13_1" => ["x86_64"],
        "Tumbleweed" => ["x86_64"],
        "rhel5" => [nil],
        "rhel6" => [nil],
        "sles11" => ["x86_64"],
        "sles12" => ["x86_64", "s390x", "power_le", "arm"]
      }

      expect(subject.integration_tests_cols).to eq(expected_cols)
    end
  end

  describe "#runs_on_cols" do
    it "returns a hash containing all runs on columns" do
      expected_cols = {
        "General commands" => [nil],
        "Package installation" => [nil]
      }

      expect(subject.runs_on_cols).to eq(expected_cols)
    end
  end

  describe "#integration_tests_rows" do
    it "returns a hash containing all rows" do
      expected_rows = {
        "openSUSE_13_1" => ["x86_64"],
        "openSUSE_13_2" => ["x86_64"],
        "sles12" => ["x86_64"]
      }
      expect(subject.integration_tests_rows).to eq(expected_rows)
    end
  end

  describe "#runs_on_rows" do
    it "returns a hash containing all runs on rows" do
      expected_rows = {
        "sles12" => ["x86_64", "s390x"],
        "openSUSE_13_1" => ["x86_64"]
      }

      expect(subject.runs_on_rows).to eq(expected_rows)
    end
  end

  describe "#append_to_list" do
    context "with colon separated value" do
      let(:value) { "parent:child" }
      it "ads the parent as key and includes the child as array" do
        expect(subject.append_to_list({}, value)).to eq("parent" => ["child"])
      end
    end
  end
end
