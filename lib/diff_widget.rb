module Machinery
  class Ui
    class DiffWidget
      def initialize(diff_text)
        diff = Machinery.scrub(diff_text)
        @lines = diff.lines[2..-1]
        @widget = {
          file: diff[/--- a(.*)/, 1],
          additions: @lines.select { |l| l.start_with?("+") }.length,
          deletions: @lines.select { |l| l.start_with?("-") }.length
        }

        @original_line_number = 0
        @new_line_number = 0
      end

      def widget
        @widget[:lines] = @lines.map do |line|
          line = ERB::Util.html_escape(line.chomp).gsub("\\", "&#92;").gsub("\t", "&nbsp;" * 8)
          case line
          when /^@.*/
            entry = header_entry(line)
            @original_line_number = line[/-(\d+)/, 1].to_i
            @new_line_number = line[/\+(\d+)/, 1].to_i
          when /^ .*/, ""
            entry = common_entry(line)
            @new_line_number += 1
            @original_line_number += 1
          when /^\+.*/
            entry = addition_entry(line)
            @new_line_number += 1
          when /^\-.*/
            entry = deletion_entry(line)
            @original_line_number += 1
          end

          entry
        end
        @widget
      end

      private

      def header_entry(line)
        {
          type: "header",
          content: line
        }
      end

      def common_entry(line)
        {
          type: "common",
          new_line_number: @new_line_number,
          original_line_number: @original_line_number,
          content: line[1..-1]
        }
      end

      def addition_entry(line)
        {
          type: "addition",
          new_line_number: @new_line_number,
          content: line[1..-1]
        }
      end

      def deletion_entry(line)
        {
          type: "deletion",
          original_line_number: @original_line_number,
          content: line[1..-1]
        }
      end
    end
  end
end
