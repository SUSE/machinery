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
  # Creates a new thread running a sinatra webserver which serves the local system descriptions
  # The Thread object is returned so that the caller can `.join` it until it's finished.
  def self.run_server(system_description_store, opts, &block)
    if opts[:public] && opts[:ip]
      raise RuntimeError.new("It's only possible to use either an IP address or the 'public' " \
        "flag bot not both.")
    end

    Thread.new do
      if opts[:public]
        opts[:ip] = "0.0.0.0"

        Machinery::Ui.warn <<-EOF.chomp
Warning:
The --public option makes the HTTP server listen on all configured IP addresses. Everyone who has access to one of those IP addresses can access all of your system descriptions stored in '~/.machinery'. Be careful if there are sensible information (such as private keys) stored in one of your descriptions.
EOF
      elsif opts[:ip] == "0.0.0.0"
        Machinery::Ui.warn <<-EOF.chomp
Warning:
The server is listening on all configured IP addresses. Everyone who has access to one of those IP addresses can access all of your system descriptions stored in '~/.machinery'. Be careful if there are sensible information (such as private keys) stored in one of your descriptions.
EOF
      elsif opts[:ip] && opts[:ip] != "localhost" && opts[:ip] != "127.0.0.1"
        Machinery::Ui.warn <<-EOF.chomp
Warning:
You specified an IP address other than '127.0.0.1', your server may be reachable from the network. Everyone who can access that network can access your system descriptions stored in '~/.machinery'. Be careful if there are sensible information (such as private keys) stored in one of your descriptions.
EOF
      elsif !opts[:ip]
        opts[:ip] = "127.0.0.1"
      end

      Server.set :system_description_store, system_description_store
      Server.set :port, opts[:port] || Machinery::Config.new.http_server_port
      Server.set :bind, opts[:ip] || "localhost"
      Server.set :public_folder, File.join(Machinery::ROOT, "html")
      Server.set :static_cache_control, "no-cache"

      begin
        setup_output_redirection
        begin
          Server.run! do
            Thread.new { block.call }
          end
        rescue Errno::EADDRINUSE
          servefailed_error = <<-EOF.chomp
Port #{Server.settings.port} is already in use.
You have to stop the already running server on port #{Server.settings.port} first or if you're serving a description with the `serve` command, you can also use the `--port` option.
EOF
          raise Machinery::Errors::ServeFailed, servefailed_error
        rescue SocketError => e
          servefailed_error = <<-EOF.chomp
Cannot start server on #{opts[:ip]}:#{Server.settings.port}.
ERROR: #{e.message}
EOF
          raise Machinery::Errors::ServeFailed, servefailed_error
        rescue Errno::EADDRNOTAVAIL
          servefailed_error = <<-EOF.chomp
The IP-Address #{opts[:ip]} is not available. Please choose a different IP-Address.
EOF
          raise Machinery::Errors::ServeFailed, servefailed_error
        rescue Errno::EACCES => e
          servefailed_error = <<-EOF.chomp
You are not allowed to start the server on port #{Server.settings.port}. You need root privileges for ports between 2 and 1023!
ERROR: #{e.message}
EOF
          raise Machinery::Errors::ServeFailed, servefailed_error
        end
        remove_output_redirection
      rescue => e
        remove_output_redirection
        # Re-raise exception in main thread
        Thread.main.raise e
      end
    end
  end

  def self.setup_output_redirection
    @orig_stdout = STDOUT.clone
    @orig_stderr = STDERR.clone
    server_log = File.join(Machinery::DEFAULT_CONFIG_DIR, "webserver.log")
    STDOUT.reopen server_log, "w"
    STDERR.reopen server_log, "w"
  end

  def self.remove_output_redirection
    STDOUT.reopen @orig_stdout
    STDERR.reopen @orig_stderr
  end
end
