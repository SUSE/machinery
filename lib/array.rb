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
            Machinery::Object.from_json(element)
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
        new(json_object)
      end
    end

    attr_reader :elements
    attr_accessor :scope

    def initialize(elements = [])
      @elements = self.class.convert_raw_array(elements)
    end

    def scope=(scope)
      @scope = scope
      @elements.each do |child|
        child.scope = @scope if child.respond_to?(:scope=)
      end
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

    def as_json
      @elements.map do |element|
        if element.is_a?(Machinery::Array) || element.is_a?(Machinery::Object)
          element.as_json
        else
          element
        end
      end
    end

    def compare_with(other)
      [
        self - other,
        other - self,
        self & other
      ].map { |e| e.empty? ? nil : e }
    end

    def method_missing(name, *args, &block)
      @elements.send(name, *args, &block)
    end

    def respond_to?(name, include_all = false)
      super || @elements.respond_to?(name, include_all)
    end
  end
end
