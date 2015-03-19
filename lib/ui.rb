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
  class Ui
    def self.internal_scope_list_to_string(scopes)
      list = Array(scopes)
      list.map { |e| e.tr("_", "-") }.join(", ")
    end

    def self.write_output_to_pager(output)
      IO.popen("$PAGER", "w") do |f|
        begin
          f.puts output
        rescue Errno::EPIPE
          # We just ignore broken pipes.
        end
      end
    end

    def self.print_output(output, options = {})
      if options[:no_pager] || !$stdout.tty?
        begin
          Machinery::Ui.puts output
        rescue Errno::EPIPE
          # We just ignore broken pipes.
        end
      else
        if !ENV['PAGER'] || ENV['PAGER'] == ''
          ENV['PAGER'] = 'less'
          ENV['LESS'] = 'FSRX'
          begin
            LocalSystem.validate_existence_of_package("less")
            write_output_to_pager(output)
          rescue Machinery::Errors::MissingRequirement
            Machinery::Ui.puts output
          end
        else
          IO.popen("$PAGER &>/dev/null", "w") { |f| f.close }
          if $?.success?
            write_output_to_pager(output)
          else
            raise(Machinery::Errors::InvalidPager.new("'#{ENV['PAGER']}' could not " \
              "be executed. Use the --no-pager option or modify your $PAGER " \
              "bash environment variable to display output.")
            )
          end
        end
      end
    end

    def self.puts(s)
      STDOUT.puts s
    end

    def self.warn(s)
      STDERR.puts s
    end

    def self.error(s)
      STDERR.puts s
    end
  end
end
