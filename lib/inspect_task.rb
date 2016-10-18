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
class Machinery::InspectTask
  def inspect_system(store, system, name, current_user, scopes, filter, options = {})
    check_root(system, current_user)

    description, failed_inspections = build_description(store, name, system,
      scopes, filter, options)

    unless description.attributes.empty?
      print_description(description, scopes) if options[:show]
    end

    unless failed_inspections.empty?
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
      renderer = Machinery::Ui::Renderer.for(scope)
      next unless renderer

      output = renderer.render(description)
      Machinery::Ui.puts output if output
    end
  end

  def build_description(store, name, system, scopes, filter, options)
    begin
      description = Machinery::SystemDescription.load(name, store)
    rescue Machinery::Errors::SystemDescriptionNotFound
      description = Machinery::SystemDescription.new(name, store)
    end
    timestring = Time.now.utc.iso8601
    host = if system.class == Machinery::LocalSystem
      "localhost"
    elsif system.class == Machinery::DockerSystem
      system.image
    else
      system.host
    end
    set_system_locale(system, description)

    failed_inspections = {}

    effective_filter = Machinery::Filter.new(description.filter_definitions("inspect"))

    scopes.each do |scope|
      inspector = Inspector.for(scope).new(system, description)
      Machinery::Ui.puts "Inspecting #{Machinery::Ui.internal_scope_list_to_string(inspector.scope)}..."

      element_filters = filter.element_filters_for_scope(scope)
      effective_filter.set_element_filters_for_scope(scope, element_filters)

      begin
        inspector.inspect(effective_filter, options)
      rescue Machinery::Errors::MachineryError => e
        Machinery::Ui.puts " -> Inspection failed!"
        failed_inspections[inspector.scope] = e
        next
      end
      description[inspector.scope].set_metadata(timestring, host)

      unless description.attributes.empty?
        effective_filter.apply!(description)
        description.set_filter_definitions("inspect", effective_filter.to_array)
        description.save
      end

      Machinery::Ui.puts " -> " + inspector.summary
    end

    return description, failed_inspections
  end

  def set_system_locale(system, description)
    Inspector.for("environment").new(system, description).inspect
    system.locale = description.environment.locale
  end
end
