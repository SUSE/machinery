class Filter
  attr_accessor :criteria

  def initialize(filter_definition = nil)
    if filter_definition.nil?
      @criteria = []
    elsif filter_definition.is_a?(String)
      @criteria = [ filter_definition ]
    elsif filter_definition.is_a?(Array)
      @criteria = filter_definition
    else
      raise "Wrong type"
    end
  end

  def add_criterion(filter_definition)
    @criteria.push(filter_definition)
  end

  def matches?(locator, value)
    @criteria.each do |criterion|
      if criterion == "#{locator}=#{value}"
        return true
      end
    end
    false
  end
end
