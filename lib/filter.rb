class Filter
  attr_accessor :path, :matcher

  def initialize(path, filter_definition = nil)
    @path = path
    @matcher = []

    raise("Wrong type") if ![NilClass, String, Array].include?(filter_definition.class)

    add_matcher(filter_definition)
  end

  def add_matcher(filter_definition)
    @matcher += Array(filter_definition)
  end

  def matches?(value)
    @matcher.each do |matcher|
      if matcher.end_with?("*")
        return true if value.start_with?(matcher[0..-2])
      else
        return true if value == matcher
      end
    end

    false
  end
end
