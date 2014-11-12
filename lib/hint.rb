# Copyright (c) 2013-2014 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

class Hint
  def self.get_started
    output "You can get started by inspecting a system. Run:\n#{$0} inspect HOSTNAME"
  end

  def self.show_data(options)
    output "To show the data of the system you just inspected run:\n#{$0} show #{options[:name]}"
  end

  def self.show_analyze_data(options)
    output "To show the config file diffs you just created run:\n" \
      "#{$0} show --scope config-files --show-diffs #{options[:name]}"
  end

  def self.do_complete_inspection(options)
    output "To do a full inspection containing all scopes and to extract files run:\n" \
     "#{$0} inspect #{options[:host]} --name #{options[:name]} --extract-files"
  end

  private

  def self.output(text)
    if Machinery::Config.new.hints
      Machinery::Ui.puts "\nHint: #{text}\n"
    end
  end
end
