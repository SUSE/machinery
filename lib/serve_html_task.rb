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

class ServeHtmlTask
  def serve(system_description_store, description, opts)
    if description
      url = "http://127.0.01:#{opts[:port]}/#{CGI.escape(description.name)}"
      Machinery::Ui.use_pager = false
      Machinery::Ui.puts <<EOF
Trying to start a web server for the description on #{url}

The web server can be closed with Ctrl+C.
EOF
    else
      url = "http://127.0.0.1:#{opts[:port]}/"
      Machinery::Ui.use_pager = false
      Machinery::Ui.puts <<EOF
Trying to start a web server for serving all system descriptions on #{url}

The web server can be closed with Ctrl+C.
EOF
    end

    server = Html.run_server(system_description_store, port: opts[:port], public: opts[:public])

    server.join
  end
end
