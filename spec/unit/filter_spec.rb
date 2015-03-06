require_relative "spec_helper"

describe Filter do
  let(:definition1) { "/unmanaged_files/files/name=/home/alfred" }
  let(:definition2) { "\"/unmanaged_files/files/name=/home/alfred,/var/cache\"" }
  let(:simple_list_definition) { "/foo=bar,/baz=qux" }
  let(:complex_definition) {
    "\"/unmanaged_files/files/name=/home/alfred,/var/cache\"," +
      "/changed_managed_files/files/name=/usr/lib/something"
  }

  describe ".parse_filter_definition" do
    it "parses element filter containing multiple matcher" do
      filters = Filter.parse_filter_definition(definition2)

      expect(filters.keys.length).to eq(1)
      expect(filters["/unmanaged_files/files/name"].path).to eq("/unmanaged_files/files/name")
      expect(filters["/unmanaged_files/files/name"].matchers).to eq(["/home/alfred", "/var/cache"])
    end

    it "parses element filter with multiple filters" do
      element_filter = Filter.parse_filter_definition(complex_definition)

      expect(element_filter.keys.length).to eq(2)
      expect(element_filter["/unmanaged_files/files/name"].path).
        to eq("/unmanaged_files/files/name")
      expect(element_filter["/unmanaged_files/files/name"].matchers).
        to eq(["/home/alfred", "/var/cache"])
      expect(element_filter["/changed_managed_files/files/name"].path).
        to eq("/changed_managed_files/files/name")
      expect(element_filter["/changed_managed_files/files/name"].matchers).
        to eq(["/usr/lib/something"])
    end

    it "parses simple lists" do
      element_filter = Filter.parse_filter_definition(simple_list_definition)
      expect(element_filter.keys.length).to eq(2)
      expect(element_filter["/foo"].matchers).
        to eq(["bar"])
      expect(element_filter["/baz"].matchers).
        to eq(["qux"])
    end
  end

  describe "#initialize" do
    it "creates Filter" do
      filter = Filter.new
      expect(filter).to be_a(Filter)
    end

    it "parses the filter definition" do
      filters = Filter.new(definition1).element_filters

      expect(filters.keys.length).to eq(1)
      expect(filters["/unmanaged_files/files/name"].path).to eq("/unmanaged_files/files/name")
      expect(filters["/unmanaged_files/files/name"].matchers).to eq(["/home/alfred"])
    end
  end

  describe "#add_filter_definition" do
    it "adds definitions" do
      filter = Filter.new("\"foo=bar,baz\"")
      filter.add_filter_definition("bar=baz")

      element_filters = filter.element_filters
      expect(element_filters["foo"].matchers).to eq(["bar", "baz"])
      expect(element_filters["bar"].matchers).to eq(["baz"])
    end

    it "merges new definitions with existing element filter" do
      filter = Filter.new("\"foo=bar,baz\"")
      filter.add_filter_definition("foo=qux")

      element_filters = filter.element_filters
      expect(element_filters["foo"].matchers).to eq(["bar", "baz", "qux"])
    end
  end

  describe "#to_array" do
    it "returns the element filter definitions as a string array" do
      filter = Filter.new("\"foo=bar,baz\",scope=matcher")
      expect(filter.to_array).to eq([
        "foo=bar,baz", "scope=matcher"
      ])
    end
  end

  describe "#filter_for" do
    it "returns the correct filter" do
      filter = Filter.new(complex_definition)

      element_filter = filter.element_filter_for("/unmanaged_files/files/name")
      expect(element_filter.path).to eq("/unmanaged_files/files/name")
      expect(element_filter.matchers).to eq(["/home/alfred", "/var/cache"])

      element_filter = filter.element_filter_for("/changed_managed_files/files/name")
      expect(element_filter.path).to eq("/changed_managed_files/files/name")
      expect(element_filter.matchers).to eq(["/usr/lib/something"])
    end
  end

  describe "#matches?" do
    let(:filter) { Filter.new(complex_definition) }

    it "returns false when no filter is set" do
      expect(filter.matches?("/some/path", "some_value")).to be(false)
    end

    it "asks the proper filter if it matches" do
      expect(filter.matches?("/unmanaged_files/files/name", "/var/cache")).to be(true)
      expect(filter.matches?("/changed_managed_files/files/name", "/var/cache")).to be(false)
    end
  end
end
