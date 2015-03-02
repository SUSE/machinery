class Filter
  attr_accessor :criteria

  def initialize(filter_definition = nil)
    @criteria = []
    @start_criteria = []
    if filter_definition.is_a?(String)
      add_criterion(filter_definition)
    elsif filter_definition.is_a?(Array)
      filter_definition.each do |definition|
        add_criterion(definition)
      end
    elsif !filter_definition.nil?
      raise "Wrong type"
    end
  end

  def add_criterion(filter_definition)
    if filter_definition.end_with?("*")
      @start_criteria.push(filter_definition[0..-2])
    else
      @criteria.push(filter_definition)
    end
  end

  def add_criteria_set(locator, value_set)
    value_set.each do |value|
      add_criterion("#{locator}=#{value}")
    end
  end

  def criteria_values(locator)
    values = []
    @criteria.each do |criterion|
      if criterion =~ /^#{locator}=(.*)$/
        values.push($1)
      end
    end
    values
  end

  def matches?(locator, value)
    match = "#{locator}=#{value}"
    @criteria.each do |criterion|
      if match == criterion
        return true
      end
    end
    @start_criteria.each do |criterion|
      if match.start_with?(criterion)
        return true
      end
    end
    false
  end
end
