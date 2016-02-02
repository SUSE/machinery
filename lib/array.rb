# Copyright (c) 2013-2016 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

module Machinery
  class Array
    class << self
      attr_reader :attribute_keys, :element_classes

      def has_attributes(*keys)
        @attribute_keys = keys.map(&:to_s)
      end

      def has_elements(options)
        @element_classes ||= []
        @element_classes << options
      end

      def from_json(json_object)
        if json_object.is_a?(::Array)
          new(json_object)
        else
          new(json_object["_elements"], json_object["_attributes"])
        end
      end
    end

    attr_reader :elements
    attr_accessor :attributes
    attr_accessor :scope

    def initialize(elements = [], attributes = {})
      attributes ||= {}
      @attribute_keys = self.class.attribute_keys || []

      unknown_attributes = attributes.keys.map(&:to_s) - @attribute_keys
      if unknown_attributes.length > 0
        raise RuntimeError, "Unknown properties: #{unknown_attributes.join(",")}"
      end

      @attributes = {}
      attributes.each do |k, v|
        @attributes[k.to_s] = v
      end
      @elements = convert_raw_array(elements)
    end

    def convert_element(element)
      (self.class.element_classes || []).each do |definition|
        condition = definition[:if]
        klass = definition[:class]
        if condition
          next if condition.any? do |key, value|
            @attributes[key.to_s] != value
          end
        end

        return element.is_a?(klass) ? element : klass.from_json(element)
      end

      case element
      when Hash
        if element.keys.include?("_elements")
          Machinery::Array.from_json(element)
        else
          Machinery::Object.from_json(element)
        end
      else
        element
      end
    end

    def convert_raw_array(array)
      array.map do |element|
        convert_element(element)
      end
    end

    def scope=(scope)
      @scope = scope
      @elements.each do |child|
        child.scope = @scope if child.respond_to?(:scope=)
      end
    end

    def to_s
      @elements.empty? ? "(empty)" : @elements.join(",")
    end

    def ==(other)
      self.class == other.class && @elements == other.elements && @attributes == other.attributes
    end

    # Various Array operators such as "-" and "&" use #eql? and #hash to compare
    # array elements, which is why we need to make sure they work properly.

    alias eql? ==

    def hash
      @elements.hash
    end

    def -(other)
      self.class.new(@elements - other.elements, @attributes)
    end

    def &(other)
      self.class.new(@elements & other.elements, @attributes)
    end

    def push(element)
      @elements.push(convert_element(element))
    end

    def <<(element)
      @elements << convert_element(element)
    end

    def +(array)
      self.class.new(@elements + self.class.new(array).elements, @attributes)
    end

    def insert(index, *elements)
      @elements.insert(index, *self.class.new(elements).elements)
    end

    def empty?
      @elements.empty?
    end

    def as_json
      object = {}

      object["_attributes"] = @attributes unless @attributes.empty?
      object["_elements"] = @elements.map do |element|
        if element.is_a?(Machinery::Array) || element.is_a?(Machinery::Object)
          element.as_json
        else
          element
        end
      end

      object
    end

    def compare_with(other)
      only_self = self.class.new(self.elements - other.elements)
      only_other = self.class.new(other.elements - self.elements)
      common = self.class.new(self.elements & other.elements)

      if self.attributes == other.attributes
        common.attributes = self.attributes
      else
        only_self.attributes = self.attributes
        only_other.attributes = other.attributes
      end

      [
        only_self,
        only_other,
        Machinery::Array.new,
        common
      ].map { |e| (e.empty? && (e.is_a?(Machinery::Array) && e.attributes.empty?)) ? nil : e }
    end

    def method_missing(name, *args, &block)
      name = name.to_s

      if @attribute_keys.include?(name)
        @attributes[name]
      elsif name.end_with?("=") and @attribute_keys.include?(name[0..-2])
        @attributes[name[0..-2]] = args.first
      else
        @elements.send(name, *args, &block)
      end
    end

    def respond_to?(name, include_all = false)
      super || @elements.respond_to?(name, include_all)
    end
  end
end
