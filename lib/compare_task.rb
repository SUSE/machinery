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

class CompareTask
  def compare(description1, description2, scopes, options = {})
    if options[:show_html]
      render_html_comparison(description1, description2, scopes, options)
    else
      output = render_comparison(description1, description2, scopes, options)

      Machinery::Ui.puts output
    end
  end

  def render_html_comparison(description1, description2, scopes, options)
    LocalSystem.validate_existence_of_command("xdg-open", "xdg-utils")

    url = "http://#{options[:ip]}:#{options[:port]}/compare/" \
      "#{CGI.escape(description1.name)}/#{CGI.escape(description2.name)}"

    Machinery::Ui.use_pager = false
    Machinery::Ui.puts <<EOF
Trying to start a web server for serving the comparison result on #{url}.

The server can be closed with Ctrl+C.
EOF

    server = Html.run_server(description1.store, port: options[:port], ip: options[:ip]) do
      LoggedCheetah.run("xdg-open", url)
    end

    server.join # Wait until the user cancelled the blocking webserver
  end

  def render_comparison(description1, description2, scopes, options = {})
    output = ""
    identical = true
    identical_scopes = []
    common_scopes = false
    scopes.each do |scope|
      if description1[scope] && description2[scope]
        comparison = Comparison.compare_scope(description1, description2, scope)

        output += Renderer.for(scope).render_comparison(comparison, options)

        if comparison.only_in1 || comparison.only_in2 || comparison.changed
          identical = false
        else
          identical_scopes << scope
        end
        common_scopes = true
      else
        output += Renderer.for(scope).render_comparison_missing_scope(
          description1, description2
        )
        identical = false if description1[scope] || description2[scope]
      end
    end
    if identical && common_scopes
      output = "\n" + output unless output.empty?
      output = "Compared descriptions are identical." + output
    elsif !identical_scopes.empty?
      phrase = Machinery::pluralize(identical_scopes.count, "scope is", "scopes are")
      output += "Following #{phrase} identical in both descriptions: " + identical_scopes.join(",")
    end

    output
  end
end
