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

class InspectTask
  def inspect_system(store, host, name, current_user, scopes, filter, options = {})
    system = System.for(host)
    check_root(system, current_user)

    description, failed_inspections = build_description(store, name, system,
      scopes, filter, options)

    if !description.attributes.empty?
      print_description(description, scopes) if options[:show]
    end

    if !failed_inspections.empty?
      Machinery::Ui.puts "\n"
      message = failed_inspections.map { |scope, msg|
        "Errors while inspecting " \
          "#{Machinery::Ui.internal_scope_list_to_string(scope)}:\n -> #{msg}" }.join("\n\n")
      raise Machinery::Errors::InspectionFailed.new(message)
    end
    description
  end

  private

  def check_root(system, current_user)
    if system.requires_root? && !current_user.is_root?
      raise Machinery::Errors::MissingRequirement,
            "Need to be root to inspect local system."
    end
  end

  def print_description(description, scopes)
    return unless scopes

    scopes.each do |scope|
      renderer = Renderer.for(scope)
      next unless renderer

      output = renderer.render(description)
      Machinery::Ui.puts output if output
    end
  end

  def adapt_filter_in_metadata(filter_in_metadata, scope, filter)
    filter_in_metadata.element_filters.
      reject! { |path, _filter| path.start_with?("/#{scope}") }
    filter.element_filters.
      select { |path, _filter| path.start_with?("/#{scope}") }.
      each do |_path, element_filter|
      filter_in_metadata.add_element_filter(element_filter)
    end
  end

  def build_description(store, name, system, scopes, filter, options)
    begin
      description = SystemDescription.load(name, store)
    rescue Machinery::Errors::SystemDescriptionNotFound
      description = SystemDescription.new(name, store)
    end
    timestring = Time.now.utc.iso8601
    if system.class == LocalSystem
      host = "localhost"
    else
      host = system.host
    end

    failed_inspections = {}

    if description.filters["inspect"]
      filter_in_metadata = description.filters["inspect"]
    else
      filter_in_metadata = Filter.new
    end

    scopes.map { |s| Inspector.for(s) }.each do |inspector|
      Machinery::Ui.puts "Inspecting #{Machinery::Ui.internal_scope_list_to_string(inspector.scope)}..."
      begin
        inspector.inspect(system, description, filter, options)
      rescue Machinery::Errors::MachineryError => e
        Machinery::Ui.puts " -> Inspection failed!"
        failed_inspections[inspector.scope] = e
        next
      end
      description[inspector.scope].set_metadata(timestring, host)

      adapt_filter_in_metadata(filter_in_metadata, inspector.scope, filter)

      if !description.attributes.empty?
        description.set_filter("inspect", filter_in_metadata)
        description.save
      end

      Machinery::Ui.puts " -> " + inspector.summary(description)
    end

    return description, failed_inspections
  end
end
