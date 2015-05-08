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
    class <<self
      attr_accessor :use_pager

      def internal_scope_list_to_string(scopes)
        list = Array(scopes)
        list.map { |e| e.tr("_", "-") }.join(", ")
      end

      def write_output_to_pager(output)
        @pager ||= IO.popen("$PAGER", "w")

        # cache the pid because it can no longer be retrieved when the
        # stream is closed (and we sometimes have to kill the process after
        # it was closed)
        @pager_pid = @pager.pid

        begin
          @pager.puts output
        rescue Errno::EPIPE
          # We just ignore broken pipes.
        end
      end

      def close_pager
        @pager.close if @pager
      end

      def kill_pager
        Process.kill("TERM", @pager_pid) if @pager_pid
      end

      def print(output)
        if !use_pager || !$stdout.tty?
          begin
            STDOUT.print output
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
              STDOUT.print output
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

      def puts(output)
        print output + "\n"
      end

      def warn(s)
        STDERR.puts s
      end

      def error(s)
        STDERR.puts s
      end
    end
  end
end
