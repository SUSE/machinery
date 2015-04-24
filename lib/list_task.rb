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

class ListTask
  def list(store, options = {})
    descriptions = store.list
    has_incompatible_version = false

    descriptions.each do |name|
      begin
        description = SystemDescription.load(name, store, skip_validation: true)
      rescue Machinery::Errors::SystemDescriptionIncompatible => e
        if !e.format_version
          show_error("#{name}: incompatible format version. Can not be upgraded.\n", options)
        elsif e.format_version < SystemDescription::CURRENT_FORMAT_VERSION
          show_error("#{name}: format version #{e.format_version}, " \
            "needs to be upgraded.\n", options)
          has_incompatible_version = true
        else
          show_error("#{name}: format version #{e.format_version}. " \
            "Please upgrade Machinery to the latest version.\n", options)
        end
        next
      rescue Machinery::Errors::SystemDescriptionValidationFailed
        show_error("#{name}: This description is broken. Use " \
          "`#{$0} validate #{name}` to see the error message.\n", options)
        next
      rescue Machinery::Errors::SystemDescriptionError
        show_error("#{name}: This description is broken.\n", options)
        next
      end

      if options[:short]
        Machinery::Ui.puts name
      else
        scopes = []

        Inspector.sort_scopes(description.scopes).each do |scope|
          entry = Machinery::Ui.internal_scope_list_to_string(scope)
          if SystemDescription::EXTRACTABLE_SCOPES.include?(scope)
            if description.scope_extracted?(scope)
              entry += " (extracted)"
            else
              entry += " (not extracted)"
            end
          end

          if options[:verbose]
            meta = description[scope].meta
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

        Machinery::Ui.puts " #{name}:\n   * " + scopes .join("\n   * ") + "\n\n"
      end
    end

    Hint.print(:upgrade_system_description) if has_incompatible_version
  end

  private

  def show_error(error_message, options)
    if options[:short]
      Machinery::Ui.puts(error_message)
    else
      Machinery::Ui.puts(" " + error_message + "\n")
    end
  end
end
