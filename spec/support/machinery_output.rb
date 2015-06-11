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

module MachineryOutput
  def self.included(klass)
    klass.extend(self)
  end

  def silence_machinery_output
    before(:each) do
      [:puts, :warn, :error, :progress].each do |method|
        allow(Machinery::Ui).to receive(method)
      end
    end
  end

  def capture_machinery_output
    before(:each) do
      stub_const(
        "Machinery::Ui", Class.new(Machinery::Ui) do
          def self.puts(s)
            @output ||= ""
            @stdout ||= ""
            @output += s + "\n"
            @stdout += s + "\n"
          end

          def self.print(s)
            @output ||= ""
            @stdout ||= ""
            @output += s
            @stdout += s
          end

          def self.warn(s)
            @output ||= ""
            @stderr ||= ""
            @output += s + "\n"
            @stderr += s + "\n"
          end

          def self.error(s)
            warn(s)
          end

          def self.output
            @output
          end

          def self.stdout
            @stdout
          end

          def self.stderr
            @stderr
          end
        end
      )
    end
  end

  def captured_machinery_output
    Machinery::Ui.output || ""
  end

  def captured_machinery_stdout
    Machinery::Ui.stdout || ""
  end

  def captured_machinery_stderr
    Machinery::Ui.stderr || ""
  end
end
