class ElementFilter
  attr_accessor :path, :matchers

  def initialize(path, matchers = nil)
    @path = path
    @matchers = []

    raise("Wrong type") if ![NilClass, String, Array].include?(matchers.class)

    add_matchers(matchers) if matchers
  end

  def add_matchers(matchers)
    @matchers += Array(matchers)
  end

  def matches?(value)
    @matchers.each do |matcher|
      if matcher.end_with?("*")
        return true if value.start_with?(matcher[0..-2])
      else
        return true if value == matcher
      end
    end

    false
  end
end
