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

class Html
  def self.generate(description)
    template = Haml::Engine.new(
      File.read(File.join(Machinery::ROOT, "html", "index.html.haml"))
    )
    target = description.store.description_path(description.name)

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
end
