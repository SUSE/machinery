# Copyright (c) 2013-2016 SUSE LLC
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

class StaticHtml < Exporter

  TEMPLATE_DIR = File.join(Machinery::ROOT, "html").freeze
  PARTIAL_DIR = File.join(Machinery::ROOT, "html", "partials").freeze

  include HamlHelpers

  def initialize(description)
    @description = description
  end

  def haml(source, locals:)
    Haml::Engine.new(source).render(binding, locals)
  end

  def write(directory)
    FileUtils.mkdir_p(directory)
    render_html(directory)
    copy_assets(directory)
  end

  private

  def copy_assets(directory)
    FileUtils.cp_r File.join(TEMPLATE_DIR, "assets"), directory
  end

  def render_html(directory)
    File.open(File.join(directory, "index.html"), "w") do |f|
      f.puts Haml::Engine.new(static_index_path).render(self, description: @description)
    end
  end

  def static_index_path
    File.read(File.join(TEMPLATE_DIR, "static_index.html.haml"))
  end

  def partial_path(partial)
    File.read(File.join(PARTIAL_DIR, "#{partial}.html.haml"))
  end
end
