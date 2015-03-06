class Filter
  attr_accessor :element_filters

  def self.parse_filter_definition(filter_definition)
    element_filters = {}
    filter_definition.scan(/\"([^,]*?)=([^\"]*)\"|([^,]+)=([^=]*)$|([^,]+)=([^,]*)/).
      map(&:compact).each do |path, matcher_definition|
        element_filters[path] ||= ElementFilter.new(path)
        if matcher_definition.index(",")
          element_filters[path].add_matchers([matcher_definition.split(",")])
        else
          element_filters[path].add_matchers(matcher_definition)
        end
    end

    element_filters
  end

  def initialize(filter_definition = "")
    @element_filters = Filter.parse_filter_definition(filter_definition)
  end

  def add_element_filter_from_definition(filter_definition)
    new_element_filters = Filter.parse_filter_definition(filter_definition)

    new_element_filters.each do |path, element_filter|
      @element_filters[path] ||= ElementFilter.new(path)
      @element_filters[path].add_matchers(element_filter.matchers)
    end
  end

  def add_element_filter(element_filter)
    path = element_filter.path
    @element_filters[path] ||= ElementFilter.new(path)
    @element_filters[path].add_matchers(element_filter.matchers)
  end

  def to_array
    @element_filters.flat_map do |path, element_filter|
      element_filter.matchers.map do |matcher|
        "#{path}=#{Array(matcher).join(",")}"
      end
    end
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
