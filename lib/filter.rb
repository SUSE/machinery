class Filter
  attr_accessor :path, :matcher

  def initialize(path, filter_definition = nil)
    @path = path
    @matcher = []
    @start_matcher = []

    raise("Wrong type") if ![NilClass, String, Array].include?(filter_definition.class)

    add_matcher(filter_definition)
  end

  def add_matcher(filter_definition)
    Array(filter_definition).each do |matcher|
      if matcher.end_with?("*")
        @start_matcher.push(matcher[0..-2])
      else
        @matcher.push(matcher)
      end
    end
  end

  def matches?(value)
    @matcher.each do |matcher|
      if value == matcher
        return true
      end
    end
    @start_matcher.each do |matcher|
      if value.start_with?(matcher)
        return true
      end
    end
    false
  end
end
