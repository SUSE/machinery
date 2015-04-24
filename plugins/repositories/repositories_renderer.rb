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

class RepositoriesRenderer < Renderer
  def do_render
    return unless @system_description.repositories

    if @system_description.repositories.empty?
      puts "System has no repositories"
    end

    list do
      @system_description.repositories.each do |p|
        item "#{p.name}" do
          puts "URI: #{p.url}"
          puts "Alias: #{p.alias}"
          puts "Enabled: #{p.enabled ? "Yes" : "No"}"
          puts "Refresh: #{p.autorefresh ? "Yes" : "No"}" if p.autorefresh != nil
          puts "Priority: #{p.priority}" if p.priority != nil
          puts "Package Manager: #{p.package_manager}"
        end
      end
    end
  end

  def display_name
    "Repositories"
  end
end
