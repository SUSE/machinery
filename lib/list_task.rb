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

class Machinery::ListTask
  def list(store, system_descriptions, options = {})
    if options[:html]
      list_html(store, options)
    else
      if system_descriptions.empty?
        descriptions = store.list
      else
        descriptions = system_descriptions.sort
      end
      has_incompatible_version = false

      descriptions.each do |name|
        begin
          system_description = Machinery::SystemDescription.load(name, store, skip_validation: true)
        rescue Machinery::Errors::SystemDescriptionIncompatible => e
          show_error("#{e}\n", options)
          next
        rescue Machinery::Errors::SystemDescriptionNotFound
          show_error(
            "#{name}: Couldn't find a system description with the name '#{name}'.", options
          )
          next
        rescue Machinery::Errors::SystemDescriptionValidationFailed
          show_error("#{name}: This description is broken. Use " \
            "`#{Hint.program_name} validate #{name}` to see the error message.", options)
          next
        rescue Machinery::Errors::SystemDescriptionError
          show_error("#{name}: This description is broken.", options)
          next
        end

        if options[:short]
          Machinery::Ui.puts name
        else
          scopes = []

          system_description.scopes.each do |scope|
            entry = Machinery::Ui.internal_scope_list_to_string(scope)
            if Machinery::SystemDescription::EXTRACTABLE_SCOPES.include?(scope)
              if system_description.scope_extracted?(scope)
                entry += " (extracted)"
              else
                entry += " (not extracted)"
              end
            end

            if options[:verbose]
              meta = system_description[scope].meta
              if meta
                time = Time.parse(meta.modified).getlocal
                date = time.strftime "%Y-%m-%d %H:%M:%S"
                hostname = meta.hostname
              else
                date = "unknown"
                hostname = "Unknown hostname"
              end
              entry += "\n      Host: [#{hostname}]"
              entry += "\n      Date: (#{date})"
            end

            scopes << entry
          end

          Machinery::Ui.puts " #{name}:\n   * " + scopes .join("\n   * ") + "\n"
        end
      end

      Hint.print(:upgrade_system_description) if has_incompatible_version
    end
  end

  def list_html(store, options)
    begin
      Machinery::LocalSystem.validate_existence_of_command("xdg-open", "xdg-utils")

      url = "http://#{options[:ip]}:#{options[:port]}/"

      Machinery::Ui.use_pager = false
      Machinery::Ui.puts <<EOF
Trying to start a web server for serving the descriptions on #{url}.

The server can be closed with Ctrl+C.
EOF

      server = Machinery::Html.run_server(store, port: options[:port], ip: options[:ip]) do
        Machinery::LoggedCheetah.run("xdg-open", url)
      end

      server.join # Wait until the user cancelled the blocking webserver
    rescue Cheetah::ExecutionFailed => e
      raise Machinery::Errors::OpenInBrowserFailed.new(
        "Could not open system descriptions in the web browser.\n" \
          "Error: #{e}\n"
      )
    end
  end

  private

  def show_error(error_message, options)
    if options[:short]
      Machinery::Ui.puts(error_message.chomp)
    else
      Machinery::Ui.puts(" " + error_message + "\n")
    end
  end
end
