# Copyright (c) 2013-2015 SUSE LLC
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
  class << self
    def print(method, options = {})
      if Machinery::Config.new.hints
        Machinery::Ui.puts to_string(method, options)
      end
    end

    def to_string(method, options = {})
      Machinery::Config.new.hints ? "\nHint: #{send(method, options)}\n" : ""
    end

    private

    def get_started(_options)
      "You can get started by inspecting a system. Run:\n#{$0} inspect HOSTNAME"
    end

    def show_data(options)
      "To show the data of the system you just inspected run:\n#{$0} show #{options[:name]}"
    end

    def show_analyze_data(options)
      "To show the config file diffs you just created run:\n" \
        "#{$0} show --scope config-files --show-diffs #{options[:name]}"
    end

    def do_complete_inspection(options)
      "To do a full inspection containing all scopes and to extract files run:\n" \
       "#{$0} inspect #{options[:host]} --name #{options[:name]} --extract-files"
    end

    def upgrade_system_description(_options)
      "To upgrade all system descriptions run:\n" \
       "#{$0} upgrade-format --all"
    end
  end
end
