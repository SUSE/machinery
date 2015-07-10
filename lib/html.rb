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
  module Helpers
    def scope_help(scope)
      text = File.read(File.join(Machinery::ROOT, "plugins", "#{scope}/#{scope}.md"))
      Kramdown::Document.new(text).to_html
    end

    def diff_to_object(diff)
      diff = Machinery.scrub(diff)
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
          gsub("\t", "&nbsp;" * 8)
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

  # this is required for the #generate_comparison method which renders a HAML template manually with
  # the local binding, so it expects the helper methods to be available in Html. It can be removed
  # once the comparison was move to the webserver approach as well
  extend Helpers

  # Creates a new thread running a sinatra webserver which serves the local system descriptions
  # The Thread object is returned so that the caller can `.join` it until it's finished.
  def self.run_server(system_description_store, opts)
    Thread.new do
      require "sinatra/base"
      require "mimemagic"

      server = Sinatra.new do
        set :port, opts[:port] || 7585
        set :bind, opts[:ip] || "localhost"
        set :public_folder, File.join(Machinery::ROOT, "html")

        helpers Helpers

        get "/descriptions/:id.js" do
          description = SystemDescription.load(params[:id], system_description_store)
          diffs_dir = description.scope_file_store("analyze/config_file_diffs").path
          if description.config_files && diffs_dir
            # Enrich description with the config file diffs
            description.config_files.files.each do |file|
              path = File.join(diffs_dir, file.name + ".diff")
              file.diff = diff_to_object(File.read(path)) if File.exists?(path)
            end
          end

          # Enrich file information with downloadable flag
          ["config_files", "changed_managed_files", "unmanaged_files"].each do |scope|
            description[scope].files.each do |file|
              file.downloadable = file.on_disk?
            end
          end

          description.to_hash.to_json
        end

        get "/descriptions/:id/files/:scope/*" do
          description = SystemDescription.load(params[:id], system_description_store)
          filename = File.join("/", params["splat"].first)

          file = description[params[:scope]].files.find { |f| f.name == filename }

          if request.accept.first.to_s == "text/plain" && file.binary?
            status 406
            return "binary file"
          end

          content = file.content
          type = MimeMagic.by_path(filename) || MimeMagic.by_magic(content) || "text/plain"

          content_type type
          attachment File.basename(filename)

          content
        end

        get "/compare/:a/:b.json" do
          description_a = SystemDescription.load(params[:a], system_description_store)
          description_b = SystemDescription.load(params[:b], system_description_store)

          diff = {
            meta: {
              description_a: description_a.name,
              description_b: description_b.name,
            }
          }

          Inspector.all_scopes.each do |scope|
            if description_a[scope] && description_b[scope]
              comparison = Comparison.compare_scope(description_a, description_b, scope)
              diff[scope] = comparison.as_json
            end
          end

          diff.to_json
        end

        get "/compare/:a/:b" do
          haml File.read(File.join(Machinery::ROOT, "html/comparison.html.haml")),
            locals: { description_a: params[:a], description_b: params[:b] }
        end

        get "/compare/:a/:b/files/:scope/*" do
          description1 = SystemDescription.load(params[:a], system_description_store)
          description2 = SystemDescription.load(params[:b], system_description_store)
          filename = File.join("/", params["splat"].first)

          begin
            diff = FileDiff.diff(description1, description2, params[:scope], filename)
          rescue Machinery::Errors::BinaryDiffError
            status 406
            return "binary file"
          end

          diff.to_s(:html)
        end

        get "/:id" do
          haml File.read(File.join(Machinery::ROOT, "html/index.html.haml")),
            locals: { description_name: params[:id] }
        end
      end

      if opts[:ip] != "localhost" && opts[:ip] != "127.0.0.1"
        Machinery::Ui.puts <<EOF
Warning:
You specified an IP address other than '127.0.0.1', your server may be reachable from the network.
This could lead to confidential data like passwords or private keys being readable by others.
EOF
      end

      begin
        setup_output_redirection
        server.run!
      rescue => e
        # Re-raise exception in main thread
        Thread.main.raise e
      ensure
        remove_output_redirection
      end
    end
  end

  def self.when_server_ready(ip, port, &block)
    20.times do
      begin
        TCPSocket.new(ip, port).close
        block.call
        return
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        sleep 0.1
      end
    end
    raise Machinery::Errors::MachineryError, "The web server did not come up in time."
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

  def self.generate_comparison(diff, target)
    FileUtils.mkdir_p(File.join(target, "assets"))
    template = Haml::Engine.new(
      File.read(File.join(Machinery::ROOT, "html", "comparison.html.haml"))
    )

    FileUtils.cp_r(File.join(Machinery::ROOT, "html", "assets"), target)
    File.write(File.join(target, "index.html"), template.render(binding))
    json = diff.to_json.gsub("'", "\\\\'").gsub("\"", "\\\\\"")
    File.write(File.join(target, "assets/diff.js"),<<-EOT
      function getDiff() {
        return JSON.parse('#{json}'
        )
      }
      EOT
    )
  end
end
