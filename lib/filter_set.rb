class FilterSet
  attr_accessor :filters

  def initialize(filter_definition)
    @filters = {}

    filter_definition.scan(/\"?([^,]*?)=([^\"]*)\"?,?/).each do |path, matcher|
      @filters[path] = Filter.new(path, matcher.split(","))
    end
  end

  def matches?(locator, value)
    filter = filter_for(locator)
    return false if !filter

    filter.matches?(value)
  end

  def filter_for(locator)
    filters[locator]
  end
end
