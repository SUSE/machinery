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

class ConfigFilesRenderer < Renderer
  def do_render
    return unless @system_description["config_files"]

    if @system_description.name
      diffs_dir = @system_description.file_store("config-file-diffs")
    end

    if !diffs_dir && @options[:show_diffs]
      raise Machinery::Errors::SystemDescriptionError.new(
        "Diffs can not be shown because they were not generated yet.\n" \
        "You can generate them with `#{$0} analyze --operation=config-file-diffs #{@system_description.name}`."
      )
    end

    list do
      file_status = @system_description["config_files"].extracted
      if !file_status.nil?
        puts "Files extracted: #{file_status ? "yes" : "no"}"
      end
      files = @system_description["config_files"].files
      if files
        files.each do |p|
          item_content = "#{p.name} (#{p.package_name}-#{p.package_version}, " \
            "#{p.changes.join(", ")})"
          if @options[:show_diffs] && p.changes.include?("md5")
            item item_content do
              render_diff_file(diffs_dir, p.name)
            end
          else
            item item_content
          end
        end
      end
    end
  end

  def display_name
    "Changed configuration files"
  end

  private

  def render_diff_file(diffs_dir, name)
    path = File.join(diffs_dir, name + ".diff")

    if File.exists?(path)
      puts "Diff:\n#{File.read(path)}"
    else
      Machinery::Ui.warn "Diff for #{name} was not found on disk."
    end
  end
end
