# frozen_string_literal: true
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

  def initialize(description, directory)
    @description = description
    @directory = directory
    @static_html = true
  end
  attr_reader :description

  def haml(source, options = {})
    Haml::Engine.new(source).render(binding, options.delete(:locals))
  end

  def write
    @description.load_existing_diffs
    render_html
    copy_assets
  end

  def create_directory(force = false)
    if File.exist?(@directory)
      if force
        FileUtils.rm_r(@directory)
      else
        raise Machinery::Errors::ExportFailed.new(
          "The output directory '#{@directory}' already exists." \
          " You can force overwriting it with the '--force' option."
        )
      end
    end
    FileUtils.mkdir_p(@directory)
  end

  private

  def copy_assets
    FileUtils.cp_r(File.join(TEMPLATE_DIR, "assets"), @directory)
    FileUtils.rm_r(File.join(@directory, "assets", "compare"))
  end

  def render_html
    File.open(File.join(@directory, "index.html"), "w") do |f|
      f.puts Haml::Engine.new(static_index_path).render(self, description: @description)
    end
  end

  def static_index_path
    File.read(File.join(TEMPLATE_DIR, "index.html.haml"))
  end

  def partial_path(partial)
    File.read(File.join(PARTIAL_DIR, "#{partial}.html.haml"))
  end
end
