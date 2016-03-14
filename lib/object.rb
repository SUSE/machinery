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
  class Object
    class << self
      def has_property(name, options)
        @property_classes ||= {}
        @property_classes[name.to_s] = options[:class]
      end

      def convert_element(key, value)
        property_class = @property_classes[key.to_s] if @property_classes
        if property_class
          value.is_a?(property_class) ? value : property_class.from_json(value)
        else
          case value
          when Hash
            if value.keys.include?("_elements")
              Machinery::Array.from_json(value)
            else
              Machinery::Object.from_json(value)
            end
          else
            value
          end
        end
      end

      def convert_raw_hash(hash)
        return nil unless hash

        entries = hash.map do |key, value|
          [key, convert_element(key, value)]
        end

        Hash[entries]
      end

      def from_json(json_object)
        new(json_object)
      end
    end

    attr_reader :attributes
    attr_accessor :scope

    def initialize(attrs = {})
      set_attributes(attrs)
    end

    def scope=(scope)
      @scope = scope
      @attributes.values.each do |child|
        child.scope = @scope if child.respond_to?(:scope=)
      end
    end

    def set_attributes(attrs)
      attrs = self.class.convert_raw_hash(attrs) if attrs.is_a?(Hash)
      @attributes = attrs.inject({}) do |attributes, (key, value)|
        key = key.to_s if key.is_a?(Symbol)

        attributes[key] = value
        attributes
      end
    end

    def ==(other)
      self.class == other.class && @attributes == other.attributes
    end

    # Various Array operators such as "-" and "&" use #eql? and #hash to compare
    # array elements, which is why we need to make sure they work properly.

    alias eql? ==

    def hash
      @attributes.hash
    end

    def [](key)
      @attributes[key.to_s]
    end

    def []=(key, value)
      @attributes[key.to_s] = self.class.convert_element(key, value)
    end

    def empty?
      @attributes.keys.empty?
    end

    def method_missing(name, *args, &block)
      if name.to_s.end_with?("=")
        if args.size != 1
          raise ArgumentError, "wrong number of arguments (#{args.size} for 1)"
        end
        key = name.to_s[0..-2]
        @attributes[key] = self.class.convert_element(key, args.first)
      else
        if @attributes.has_key?(name.to_s)
          unless args.empty?
            raise ArgumentError, "wrong number of arguments (#{args.size} for 0)"
          end

          @attributes[name.to_s]
        else
          nil
        end
      end
    end

    def respond_to?(name, include_all = false)
      if name.to_s.end_with?("=")
        true
      else
        @attributes.has_key?(name) || super(name, include_all)
      end
    end

    def initialize_copy(orig)
      super
      @attributes = @attributes.dup
    end

    def as_json
      entries = @attributes.map do |key, value|
        case value
        when Machinery::Array, Machinery::Object
          value_json = value.as_json
        else
          value_json = value
        end

        [key, value_json]
      end

      Hash[entries]
    end

    def compare_with(other)
      self == other ? [nil, nil, nil, self] : [self, other, nil, nil]
    end
  end
end
