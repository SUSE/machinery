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
      return if !Machinery::Config.new.hints

      Machinery::Ui.puts to_string(method, options)
    end

    def to_string(method, options = {})
      return "" if !Machinery::Config.new.hints

      "\nHint: #{send(method, options)}\n"
    end

    def program_name
      if which_machinery == $PROGRAM_NAME
        "machinery"
      else
        $PROGRAM_NAME
      end
    end

    private

    def which_machinery
      `which machinery 2>/dev/null`.chomp
    end

    def get_started(_options)
      "You can get started by inspecting a system. Run:\n#{program_name} inspect HOSTNAME"
    end

    def upgrade_format_force(options)
      "To force an upgrade of system descriptions run:\n" \
      "#{program_name} upgrade-format --force #{options[:name]}"
    end

    def show_data(options)
      "To show the data of the system you just inspected run:\n#{program_name} show #{options[:name]}"
    end

    def show_analyze_data(options)
      "To show the config file diffs you just created run:\n" \
        "#{program_name} show --scope config-files --show-diffs #{options[:name]}"
    end

    def do_complete_inspection(options)
      if options[:host]
        "To do a full inspection containing all scopes and to extract files run:\n" \
         "#{program_name} inspect #{options[:host]} --name #{options[:name]} --extract-files"
      elsif options[:docker_container]
        "To do a full inspection containing all scopes and to extract files run:\n" \
         "#{program_name} inspect-container --docker #{options[:docker_container]} " \
         "--name #{options[:name]} --extract-files"
      end
    end

    def upgrade_system_description(_options)
      "To upgrade all system descriptions run:\n" \
       "#{program_name} upgrade-format --all"
    end

    def share_html_contents(options)
      dir = options[:directory] || ""
      index_file = File.join(dir, "index.html")
      assets_dir = File.join(dir, "assets/")
      "Share the file: '#{index_file}' and the directory: '#{assets_dir}' as needed."
    end
  end
end
