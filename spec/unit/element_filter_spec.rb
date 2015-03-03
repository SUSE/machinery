require_relative "spec_helper"

describe ElementFilter do
  before(:each) do
    @path = "/unmanaged_files/files/name"
    @matcher1 = "/home/alfred"
    @matcher2 = "/var/cache"
  end

  describe "#initialize" do
    it "creates filter object" do
      filter = ElementFilter.new(@path)
      expect(filter).to be_a(ElementFilter)
    end

    it "creates filter object with one definition" do
      filter = ElementFilter.new(@path, @matcher1)
      expect(filter.matchers).to eq([@matcher1])
    end

    it "creates filter object with an array of definitions" do
      matcher = [@matcher1, @matcher2]
      filter = ElementFilter.new(@path, matcher)
      expect(filter.matchers).to eq(matcher)
    end
  end

  describe "#add_matcher" do
    it "adds one matcher definition" do
      filter = ElementFilter.new(@path)
      filter.add_matchers(@matcher1)
      expect(filter.matchers).to eq([@matcher1])
    end

    it "adds two matcher definition" do
      filter = ElementFilter.new(@path)
      filter.add_matchers(@matcher1)
      filter.add_matchers(@matcher2)
      expect(filter.matchers).to eq([@matcher1, @matcher2])
    end

    it "adds set of two definitions" do
      filter = ElementFilter.new(@path)
      filter.add_matchers(["/home/alfred", "/var/cache"])
      expect(filter.matchers).to eq([@matcher1, @matcher2])
    end
  end

  describe "#matchers" do
    it "returns all matchers" do
      filter = ElementFilter.new(@path, [@matcher1, @matcher2])
      expect(filter.matchers).to eq(["/home/alfred", "/var/cache"])
    end
  end

  describe "#matches?" do
    it "returns true on matching value" do
      filter = ElementFilter.new(@path, @matcher1)
      expect(filter.matches?("/home/alfred")).
        to be(true)
    end

    it "returns false on non-matching value" do
      filter = ElementFilter.new(@path, @matcher1)
      expect(filter.matches?("/home/berta")).
        to be(false)
    end

    describe "matches beginning of a value" do
      before(:each) do
        @filter = ElementFilter.new("path", "/home/alfred/*")
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
