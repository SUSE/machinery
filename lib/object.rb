# Copyright (c) 2013-2014 SUSE LLC
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
        @property_classes[name.to_sym] = options[:class]
      end

      def hash_from_json(json)
        return nil unless json

        entries = json.map do |key, value|
          value_converted = if @property_classes && @property_classes[key.to_sym]
            @property_classes[key.to_sym].from_json(value)
          else
            case value
              when ::Array
                Machinery::Array.from_json(value)
              when Hash
                Machinery::Object.from_json(value)
              else
                value
            end
          end

          [key, value_converted]
        end

        entries
      end

      def from_json(json)
        entries = hash_from_json(json)
        new(Hash[entries])
      end
    end

    attr_reader :attributes

    def initialize(attrs = {})
      set_attributes(attrs)
    end

    def set_attributes(attrs)
      @attributes = attrs.inject({}) do |attributes, (key, value)|
        key = key.to_sym if key.respond_to?(:to_sym)

        attributes[key] = value
        attributes
      end
      self
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
      @attributes[key.to_sym]
    end

    def []=(key, value)
      @attributes[key.to_sym] = value
    end

    def empty?
      @attributes.keys.empty?
    end

    def method_missing(name, *args, &block)
      if name.to_s.end_with?("=")
        if args.size != 1
          raise ArgumentError, "wrong number of arguments (#{args.size} for 1)"
        end

        @attributes[name.to_s[0..-2].to_sym] = args.first
      else
        if @attributes.has_key?(name)
          if !args.empty?
            raise ArgumentError, "wrong number of arguments (#{args.size} for 0)"
          end

          @attributes[name]
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
      self == other ? [nil, nil, self] : [self, other, nil]
    end
  end
end
