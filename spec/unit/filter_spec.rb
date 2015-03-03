require_relative "spec_helper"

describe Filter do
  before(:each) do
    @path = "/unmanaged_files/files/name"
    @matcher1 = "/home/alfred"
    @matcher2 = "/var/cache"
  end

  describe "#initialize" do
    it "creates filter object" do
      filter = Filter.new(@path)
      expect(filter).to be_a(Filter)
    end

    it "creates filter object with one definition" do
      filter = Filter.new(@path, @matcher1)
      expect(filter.matcher).to eq([@matcher1])
    end

    it "creates filter object with an array of definitions" do
      matcher = [ @matcher1, @matcher2 ]
      filter = Filter.new(@path, matcher)
      expect(filter.matcher).to eq(matcher)
    end
  end

  describe "#add_matcher" do
    it "adds one filter definition" do
      filter = Filter.new(@path)
      filter.add_matcher(@matcher1)
      expect(filter.matcher).to eq([@matcher1])
    end

    it "adds two filter definition" do
      filter = Filter.new(@path)
      filter.add_matcher(@matcher1)
      filter.add_matcher(@matcher2)
      expect(filter.matcher).to eq([@matcher1, @matcher2])
    end

    it "adds set of two definitions" do
      filter = Filter.new(@path)
      filter.add_matcher(["/home/alfred", "/var/cache"])
      expect(filter.matcher).to eq([@matcher1, @matcher2])
    end
  end

  describe "#matcher" do
    it "returns all matcher" do
      filter = Filter.new(@path, [@matcher1, @matcher2])
      expect(filter.matcher).to eq(["/home/alfred", "/var/cache"])
    end
  end

  describe "#matches?" do
    it "returns true on matching value" do
      filter = Filter.new(@path, @matcher1)
      expect(filter.matches?("/home/alfred")).
        to be(true)
    end

    it "returns false on non-matching value" do
      filter = Filter.new(@path, @matcher1)
      expect(filter.matches?("/home/berta")).
        to be(false)
    end

    describe "matches beginning of a value" do
      before(:each) do
        @filter = Filter.new("path", "/home/alfred/*")
      end

      it "returns false on shorter value" do
        expect(@filter.matches?("/home/alfred")).to be(false)
      end

      it "returns true on minimal match" do
        expect(@filter.matches?("/home/alfred/")).to be(true)
      end

      it "returns true on longer match" do
        expect(@filter.matches?("/home/alfred/and/berta")).to be(true)
      end

      it "returns true on value with star at the end" do
        expect(@filter.matches?("/home/alfred/*")).to be(true)
      end
    end
  end
end
