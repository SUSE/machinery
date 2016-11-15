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

module Machinery
  class Ui
    class RepositoriesRenderer < Machinery::Ui::Renderer
      def content(description)
        return unless description.repositories

        if description.repositories.empty?
          puts "There are no repositories."
        end

        na_note("repository type") if description.repositories.any? { |a| a[:type] == "" }

        list do
          description.repositories.each do |p|
            item_name = if p.name
              p.name
            else
              "URI: #{p.url}"
            end
            item item_name do
              if p.url.is_a?(::Array)
                list "URI", sublist: true do
                  p.url.each do |url|
                    item url
                  end
                end
              elsif p.name
                puts "URI: #{p.url}"
              end
              puts "Mirrorlist: #{!p.mirrorlist.empty? ? p.mirrorlist : "N/A"}" if p.mirrorlist
              puts "Alias: #{p.alias}" if p.alias
              puts "Distribution: #{p.distribution}" if p.distribution
              puts "Components: #{p.components.join(", ")}" if p.components
              puts "Enabled: #{p.enabled ? "Yes" : "No"}" unless p.enabled.nil?
              puts "Refresh: #{p.autorefresh ? "Yes" : "No"}" unless p.autorefresh.nil?
              puts "Priority: #{p.priority}" unless p.priority.nil?
              puts "Type: #{p.type || "N/A"}"
            end
          end
        end
      end

      def display_name
        "Repositories"
      end

      def compare_content_changed(changed_elements)
        list do
          changed_elements.each do |one, two|
            changes = []
            relevant_attributes = one.attributes.keys

            relevant_attributes.each do |attribute|
              if one[attribute] != two[attribute]
                changes << "#{attribute}: #{one[attribute]} <> #{two[attribute]}"
              end
            end

            item "#{one.alias} (#{changes.join(", ")})"
          end
        end
      end
    end
  end
end
