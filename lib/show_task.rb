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

class ShowTask
  def show(description, scopes = nil, options = {})
    missing_scopes = []
    if scopes
      renderers = []
      failed_renderers = []

      scopes.each do |scope|
        renderer = Renderer.for(scope)

        if renderer
          renderers << renderer
        else
          failed_renderers << scope
        end
      end

      if failed_renderers.length > 0
        raise Machinery::Errors::UnknownRenderer.new(
          "The following scopes are not supported: " \
          "#{Cli.internal_to_cli_scope_names(failed_renderers).join(",")}. " \
          "Valid scopes are: " \
          "#{Cli.internal_to_cli_scope_names(Inspector.all_scopes).join(",")}."
        )
      end
    else
      renderers = Renderer.all
    end

    output = ""
    renderers.each do |renderer|
      section = renderer.render(description, options)
      unless section.empty?
        output += section
      else
        missing_scopes << renderer.scope
      end
    end

    if missing_scopes.length > 0
      output += "# The following requested scopes were not inspected\n\n"
      missing_scopes.each do |scope|
        output += "  * #{Cli.internal_to_cli_scope_names(scope).join(",")}\n"
      end
    end

    Machinery::print_output(output, :no_pager => options[:no_pager])
  end
end
