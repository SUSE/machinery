class Filter
  attr_accessor :element_filters

  def initialize(filter_definition = "")
    @element_filters = parse_filter_definition(filter_definition)
  end

  def parse_filter_definition(filter_definition)
    element_filters = {}
    filter_definition.scan(/\"?([^,]*?)=([^\"]*)\"?,?/).each do |path, matcher_definition|
      element_filters[path] = ElementFilter.new(path, matcher_definition.split(","))
    end

    element_filters
  end

  def matches?(path, value)
    filter = element_filter_for(path)
    return false if !filter

    filter.matches?(value)
  end

  def element_filter_for(path)
    element_filters[path]
  end
end
