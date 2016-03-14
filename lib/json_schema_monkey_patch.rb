# Quick and dirty monkey patch for a performance bug we saw with certain
# schema constellations
#
# The performance issues are that
#   * `build_fragment` joins the elements in `fragments` even though the
#     error message it is used in is never used
#   * the `fragment` array constantly grows
module JSON
  class Schema
    class EnumAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        unless current_schema.schema["enum"].include?(data)
          if options[:record_errors]
            message = "The property '#{build_fragment(fragments)}' value #{data.inspect} did not match one of the following values:"
            current_schema.schema["enum"].each {|val|
              if val.is_a?(NilClass)
                message += " null,"
              elsif val.is_a?(Array)
                message += " (array),"
              elsif val.is_a?(Hash)
                message += " (object),"
              else
                message += " #{val.to_s},"
              end
            }
            message.chop!
            validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
          else
            raise ValidationError.new("", [], nil, current_schema)
          end
        end
      end
    end
  end
end
