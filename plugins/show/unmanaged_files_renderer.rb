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

class UnmanagedFilesRenderer < Renderer
  def do_render
    return unless @system_description["unmanaged_files"]

    list do
      @system_description["unmanaged_files"].files.each do |p|
        if p.user && p.group
          item "#{p.name} (#{p.type})" do
            puts "User/Group: #{p.user}:#{p.group}"
            puts "Mode: #{p.mode}" if p.mode
            puts "Size: #{number_to_human_size(p.size)}" if p.size
            puts "Files: #{p.files}" if p.files
          end
        else
          item "#{p.name} (#{p.type})"
        end
      end
    end
  end

  def display_name
    "Unmanaged files"
  end
end
