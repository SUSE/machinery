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

class ShowTask
  def show(description, scopes, filter, options = {})
    scopes = Inspector.sort_scopes(scopes)
    if options[:show_html]
      show_html(description, options)
    else
      filter.apply!(description)
      show_console(description, scopes, options )
    end
  end

  private

  def show_html(description, options)
    begin
      LocalSystem.validate_existence_of_package("xdg-utils")

      url = "http://#{options[:ip]}:#{options[:port]}/#{CGI.escape(description.name)}"

      Machinery::Ui.use_pager = false
      Machinery::Ui.puts <<EOF
Machinery will try to start a web server for serving the description on #{url}.

The server can be closed with Ctrl+C.
EOF

      server = Html.run_server(description.store, port: options[:port], ip: options[:ip]) do
        LoggedCheetah.run("xdg-open", url)
      end

      server.join # Wait until the user cancelled the blocking webserver
    rescue Cheetah::ExecutionFailed => e
      raise Machinery::Errors::OpenInBrowserFailed.new(
        "Could not open system description '#{description.name}' in the web browser.\n" \
          "Error: #{e}\n"
      )
    end
  end

  def show_console(description, scopes, options)
    missing_scopes = []

    scopes.map { |s| Renderer.for(s) }.each do |renderer|
      section = renderer.render(description, options)
      unless section.empty?
        Machinery::Ui.puts section
      else
        missing_scopes << renderer.scope
      end
    end

    if missing_scopes.length > 0
      Machinery::Ui.puts "# The following requested scopes were not inspected\n\n"
      missing_scopes.each do |scope|
        Machinery::Ui.puts "  * #{Machinery::Ui.internal_scope_list_to_string(scope)}\n"
      end
    end
  end
end
