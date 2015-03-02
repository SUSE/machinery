require_relative "spec_helper"

describe Filter do
  before(:each) do
    @criterion1 = "/unmanaged_files/files/name=/home/alfred"
    @criterion2 = "/unmanaged_files/files/name=/var/cache"
  end

  describe "#initialize" do
    it "creates filter object" do
      filter = Filter.new
      expect(filter).to be_a(Filter)
    end

    it "creates filter object with one definition" do
      filter = Filter.new(@criterion1)
      expect(filter.criteria).to eq([@criterion1])
    end

    it "creates filter object with an array of definitions" do
      filter_criteria = [ @criterion1, @criterion2 ]
      filter = Filter.new(filter_criteria)
      expect(filter.criteria).to eq(filter_criteria)
    end
  end

  describe "#add_criterion" do
    it "adds one filter definition" do
      filter = Filter.new
      filter.add_criterion(@criterion1)
      expect(filter.criteria).to eq([@criterion1])
    end

    it "adds two filter definition" do
      filter = Filter.new
      filter.add_criterion(@criterion1)
      filter.add_criterion(@criterion2)
      expect(filter.criteria).to eq([@criterion1, @criterion2])
    end
  end

  describe "#add_criterion_set" do
    it "adds set of two definitions" do
      filter = Filter.new
      filter.add_criteria_set("/unmanaged_files/files/name",
        ["/home/alfred", "/var/cache"])
      expect(filter.criteria).to eq([@criterion1, @criterion2])
    end
  end

  describe "#criteria_values" do
    it "returns criteria values for given locator" do
      filter = Filter.new([@criterion1, @criterion2])
      expect(filter.criteria_values("/unmanaged_files/files/name")).
        to eq(["/home/alfred", "/var/cache"])
    end
  end

  describe "#matches?" do
    it "returns true on matching value" do
      filter = Filter.new(@criterion1)
      expect(filter.matches?("/unmanaged_files/files/name", "/home/alfred")).
        to be(true)
    end

    it "returns false on non-matching value" do
      filter = Filter.new(@criterion1)
      expect(filter.matches?("/unmanaged_files/files/name", "/home/berta")).
        to be(false)
    end

    describe "matches beginning of a value" do
      before(:each) do
        @filter = Filter.new("path=/home/alfred/*")
      end

      it "returns false on shorter value" do
        expect(@filter.matches?("path", "/home/alfred")).to be(false)
      end

      it "returns true on minimal match" do
        expect(@filter.matches?("path", "/home/alfred/")).to be(true)
      end

      it "returns true on longer match" do
        expect(@filter.matches?("path", "/home/alfred/and/berta")).to be(true)
      end

      it "returns true on value with star at the end" do
        expect(@filter.matches?("path", "/home/alfred/*")).to be(true)
      end
    end
  end
end
