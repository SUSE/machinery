require "yaml"
require_relative "support_matrix/ods_formatter"
require_relative "support_matrix/pdf_formatter"

class SupportMatrix
  attr_reader :path
  attr_accessor :formatter

  def initialize(path, formatter)
    @path = path.is_a?(Array) ? path : [path]
    @formatter = formatter
  end

  def write(path)
    formatter.write(self, path)
  end

  def merge_source(name)
    result = {}
    path.each do |p|
      result.merge!(YAML.load_file(File.join(p, "#{name}.yml")))
    end
    result
  end

  [:integration_tests, :unit_tests, :runs_on].each do |m|
    define_method(m) do
      merge_source(__method__)
    end
  end

  def append_to_list(list, value)
    left, right = value.split(":")
    list[left] ||= []
    list[left].push(right) unless list[left].include?(right)
    list
  end

  def integration_tests_cols
    result = {}
    integration_tests.each do |_test, support_levels|
      support_levels.each do |_level, matrix|
        matrix.each do |_host, targets|
          targets.each do |guest, _support_data|
            append_to_list(result, guest)
          end
        end
      end
    end
    result
  end

  def runs_on_cols
    result = {}
    runs_on.each do |_level, matrix|
      matrix.each do |_host, targets|
        targets.each do |guest, _support_data|
          append_to_list(result, guest)
        end
      end
    end
    result
  end

  def integration_tests_rows
    result = {}
    integration_tests.each do |_test, support_levels|
      support_levels.each do |_level, matrix|
        matrix.keys.each do |host|
          append_to_list(result, host)
        end
      end
    end
    result
  end

  def runs_on_rows
    result = {}
    runs_on.each do |_level, matrix|
      matrix.keys.each do |host|
        append_to_list(result, host)
      end
    end
    result
  end

  def test_group_char
    {
      "full_test" => "F",
      "acceptance_test" => "A",
      "minimal_test" => "M"
    }
  end
end
