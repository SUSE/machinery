# Copyright (c) 2013-2015 SUSE LLC
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
      attr_reader :attribute_keys

      def initialize
        @attribute_keys = {}
        super
      end

      def has_attributes(*keys)
        @attribute_keys = keys.map(&:to_s)
      end

      def has_elements(options)
        @element_class = options[:class]
      end

      def convert_element(element)
        if @element_class
          element.is_a?(@element_class) ? element : @element_class.from_json(element)
        else
          case element
          when ::Array
            Machinery::Array.from_json(element)
          when Hash
            if element.keys.sort == ["_attributes", "_elements"]
              Machinery::Array.from_json(element)
            else
              Machinery::Object.from_json(element)
            end
          else
            element
          end
        end
      end

      def convert_raw_array(array)
        array.map do |element|
          convert_element(element)
        end
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
      @attribute_keys = self.class.attribute_keys || []

      unknown_attributes = attributes.keys.map(&:to_s) - @attribute_keys
      if unknown_attributes.length > 0
        raise RuntimeError, "Unknown properties: #{unknown_attributes.join(",")}"
      end

      @attributes = attributes
      @elements = self.class.convert_raw_array(elements)
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
      self.class == other.class && @elements == other.elements
    end

    # Various Array operators such as "-" and "&" use #eql? and #hash to compare
    # array elements, which is why we need to make sure they work properly.

    alias eql? ==

    def hash
      @elements.hash
    end

    def -(other)
      self.class.new(@elements - other.elements)
    end

    def &(other)
      self.class.new(@elements & other.elements)
    end

    def push(element)
      @elements.push(self.class.convert_element(element))
    end

    def <<(element)
      @elements << self.class.convert_element(element)
    end

    def +(array)
      self.class.new(@elements + self.class.new(array).elements)
    end

    def insert(index, *elements)
      @elements.insert(index, *self.class.new(elements).elements)
    end

    def empty?
      @elements.empty? && @attributes.empty?
    end

    def as_json
      {
        "_attributes" => @attributes,
        "_elements" => @elements.map do |element|
          if element.is_a?(Machinery::Array) || element.is_a?(Machinery::Object)
            element.as_json
          else
            element
          end
        end
      }
    end

    def compare_with(other)
      only_self = self - other
      only_other = other - self
      common = self & other

      if self.attributes == other.attributes
        common.attributes = self.attributes
      else
        only_self.attributes = self.attributes
        only_other.attributes = other.attributes
      end

      [
        only_self,
        only_other,
        [],
        common
      ].map { |e| e.empty? ? nil : e }
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
