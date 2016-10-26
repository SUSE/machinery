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

class Machinery::ServeHtmlTask
  def assemble_url(opts)
    host = if !opts[:public]
      "127.0.0.1"
    else
      begin
        Socket.gethostbyname(Socket.gethostname).first
      rescue SocketError
        Socket.gethostname
      end
    end
    "http://#{host}:#{opts[:port]}/"
  end

  def serve(system_description_store, opts)
    url = assemble_url(opts)
    Machinery::Ui.use_pager = false
    Machinery::Ui.puts <<EOF
Trying to start a web server for serving a view on all system descriptions.

The overview of all descriptions is accessible at:

    #{url}

A specific description with the name NAME is accessible at:

    #{url}NAME

The web server can be closed with Ctrl+C.
EOF

    server = Machinery::Html.run_server(
      system_description_store,
      port: opts[:port],
      public: opts[:public]
    )

    server.join
  end
end
