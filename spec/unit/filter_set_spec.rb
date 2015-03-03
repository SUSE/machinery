require_relative "spec_helper"

describe FilterSet do
  let(:definition1) { "/unmanaged_files/files/name=/home/alfred" }
  let(:definition2) { "/unmanaged_files/files/name=/home/alfred,/var/cache" }
  let(:complex_definition) {
    "\"/unmanaged_files/files/name=/home/alfred,/var/cache\"," +
      "/changed_managed_files/files/name=/usr/lib/something"
  }

  describe "#initialize" do
    it "creates FilterSet" do
      filter_set = FilterSet.new("")
      expect(filter_set).to be_a(FilterSet)
    end

    it "creates FilterSet with one filter" do
      filters = FilterSet.new(definition1).filters

      expect(filters.keys.length).to eq(1)
      expect(filters["/unmanaged_files/files/name"].path).to eq("/unmanaged_files/files/name")
      expect(filters["/unmanaged_files/files/name"].matcher).to eq(["/home/alfred"])
    end

    it "creates FilterSet with one filter containing multiple matcher" do
      filters = FilterSet.new(definition2).filters

      expect(filters.keys.length).to eq(1)
      expect(filters["/unmanaged_files/files/name"].path).to eq("/unmanaged_files/files/name")
      expect(filters["/unmanaged_files/files/name"].matcher).to eq(["/home/alfred", "/var/cache"])
    end

    it "creates FilterSet with multiple filters" do
      filters = FilterSet.new(complex_definition).filters

      expect(filters.keys.length).to eq(2)
      expect(filters["/unmanaged_files/files/name"].path).to eq("/unmanaged_files/files/name")
      expect(filters["/unmanaged_files/files/name"].matcher).to eq(["/home/alfred", "/var/cache"])
      expect(filters["/changed_managed_files/files/name"].path).
        to eq("/changed_managed_files/files/name")
      expect(filters["/changed_managed_files/files/name"].matcher).to eq(["/usr/lib/something"])
    end
  end

  describe "#filter_for" do
    it "returns the correct filter" do
      filter_set = FilterSet.new(complex_definition)

      filter = filter_set.filter_for("/unmanaged_files/files/name")
      expect(filter.path).to eq("/unmanaged_files/files/name")
      expect(filter.matcher).to eq(["/home/alfred", "/var/cache"])

      filter = filter_set.filter_for("/changed_managed_files/files/name")
      expect(filter.path).to eq("/changed_managed_files/files/name")
      expect(filter.matcher).to eq(["/usr/lib/something"])
    end
  end

  describe "#matches?" do
    let(:filter_set) { FilterSet.new(complex_definition) }

    it "returns false when no filter is set" do
      expect(filter_set.matches?("/some/path", "some_value")).to be(false)
    end

    it "asks the proper filter if it matches" do
      expect(filter_set.matches?("/unmanaged_files/files/name", "/var/cache")).to be(true)
      expect(filter_set.matches?("/changed_managed_files/files/name", "/var/cache")).to be(false)
    end
  end
end
