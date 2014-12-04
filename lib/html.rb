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

class Html
  def self.generate(description)
    template = Haml::Engine.new(
      File.read(File.join(Machinery::ROOT, "html", "index.html.haml"))
    )
    target = description.store.description_path(description.name)

    diffs_dir = description.scope_file_store("analyze/config_file_diffs").path
    if description.config_files && diffs_dir
      # Enrich description with the config file diffs
      description.config_files.files.each do |file|
        path = File.join(diffs_dir, file.name + ".diff")
        file.diff = diff_to_object(File.read(path)) if File.exists?(path)
      end
    end

    FileUtils.cp_r(File.join(Machinery::ROOT, "html", "assets"), target)
    File.write(File.join(target, "index.html"), template.render(binding))
    File.write(File.join(target, "assets/description.js"),<<-EOT
      function getDescription() {
        return JSON.parse('#{description.to_hash.to_json}')
      }
      EOT
    )
  end

  # Template helpers

  def self.scope_help(scope)
    text = File.read(File.join(Machinery::ROOT, "plugins", "docs", "#{scope}.md"))
    Kramdown::Document.new(text).to_html
  end

  def self.diff_to_object(diff)
    lines = diff.lines[2..-1]
    diff_object = {
      file: diff[/--- a(.*)/, 1],
      additions: lines.select { |l| l.start_with?("+") }.length,
      deletions: lines.select { |l| l.start_with?("-") }.length
    }

    original_line_number = 0
    new_line_number = 0
    diff_object[:lines] = lines.map do |line|
      line = ERB::Util.html_escape(line.chomp).
        gsub("\\", "&#92;").
        gsub("\t", "&nbsp;"*8)
      case line
      when /^@.*/
        entry = {
          type: "header",
          content: line
        }
        original_line_number = line[/-(\d+)/, 1].to_i
        new_line_number = line[/\+(\d+)/, 1].to_i
      when /^ .*/, ""
        entry = {
          type: "common",
          new_line_number: new_line_number,
          original_line_number: original_line_number,
          content: line[1..-1]
        }
        new_line_number += 1
        original_line_number += 1
      when /^\+.*/
        entry = {
          type: "addition",
          new_line_number: new_line_number,
          content: line[1..-1]
        }
        new_line_number += 1
      when /^\-.*/
        entry = {
          type: "deletion",
          original_line_number: original_line_number,
          content: line[1..-1]
        }
        original_line_number += 1
      end

      entry
    end

    diff_object
  end
end
