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

class ChangedManagedFilesRenderer < Renderer
  def do_render
    return unless @system_description["changed-managed-files"]

    files, errors = @system_description["changed-managed-files"].partition do |file|
      file.error.nil?
    end

    if !files.empty?
      list do
        files.each do |p|
          item "#{p.name} (#{p.changes.join(", ")})"
        end
      end
    end

    if !errors.empty?
      list("Errors") do
        errors.each do |p|
          item "#{p.name}: #{p.error}"
        end
      end
    end
  end

  def display_name
    "Changed managed files"
  end
end
