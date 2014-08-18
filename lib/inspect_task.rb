# Copyright (c) 2013-2014 SUSE LLC
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
  def inspect_system(store, host, name, current_user, scopes, options = {})
    system = System.for(host)
    check_root(system, current_user)

    description, failed_inspections = build_description(store, name, system, scopes, options)

    if !description.attributes.empty?
      description.name = name
      store.save(description)
      print_description(description, scopes) if options[:show]
    end

    if !failed_inspections.empty?
      puts "\n"
      message = failed_inspections.map { |scope, msg|
        "Errors while inspecting " \
          "#{Machinery::Ui.internal_scope_list_to_string(scope)}:\n#{msg}" }.join("\n\n")
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
      puts output if output
    end
  end

  def build_description(store, name, system, scopes, options)
    begin
      description = store.load(name)
    rescue Machinery::Errors::SystemDescriptionNotFound
      description = SystemDescription.new(name, {}, store)
    end
    timestring = Time.now.utc.iso8601
    if system.class == LocalSystem
      host = "localhost"
    else
      host = system.host
    end

    failed_inspections = {}

    scopes.map { |s| Inspector.for(s) }.each do |inspector|
      puts "Inspecting #{Machinery::Ui.internal_scope_list_to_string(inspector.scope)}..."
      begin
        summary = inspector.inspect(system, description, options)
      rescue Machinery::Errors::MachineryError => e
        puts "Inspection of scope " \
          "#{Machinery::Ui.internal_scope_list_to_string(inspector.scope)} failed!"
        failed_inspections[inspector.scope] = e
        next
      end
      description[inspector.scope].set_metadata(timestring, host)
      puts " -> " + summary
    end

    return description, failed_inspections
  end
end
