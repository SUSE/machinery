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

class Server < Sinatra::Base
  module Helpers
    def render_partial(partial, locals = {})
      source = File.read(File.join(Machinery::ROOT, "html/partials/#{partial}.html.haml"))
      haml source, locals: locals
    end

    def render_scope(scope)
      render_partial scope, scope => @description[scope]
    end

    def scope_meta_info(scope)
      return "" if !@description[scope]

      " (" \
      "inspected host: '#{@description[scope].meta.hostname}', " \
      "at: #{DateTime.parse(@description[scope].meta.modified).strftime("%F %T")})"
    end

    def scope_help(scope)
      text = scope_info(scope)[:description]
      Kramdown::Document.new(text).to_html
    end

    def scope_info(scope)
      YAML.load(File.read(File.join(Machinery::ROOT, "plugins", "#{scope}/#{scope}.yml")))
    end

    def scope_title(scope)
      scope_info(scope)[:name]
    end

    def scope_initials(scope)
      scope_info(scope)[:initials].upcase
    end

    def nav_class(scope)
      if @description
        return @description[scope] ? "" : "disabled"
      elsif @description_a && @description_b
        return @description_a[scope] && @description_b[scope] ? "" : "disabled"
      end
    end

    def safe_length(object, attribute)
      if collection = object.try(attribute)
        collection.length
      else
        0
      end
    end

    def only_in_a
      "<h3>Only in '#{@description_a.name}':</h3>"
    end

    def only_in_b
      "<h3>Only in '#{@description_b.name}':</h3>"
    end

    def in_both
      "<h3>In both descriptions:</h3>"
    end

    def changed
      "<h3>In both with different attributes:</h3>"
    end

    def pluralize_scope(object, singular, plural)
      object.length.to_s + " " + Machinery.pluralize(object.length, singular, plural)
    end

    def changed_elements(scope, opts)
      optional_attributes = opts[:optional_attributes] || []

      changed = []
      @diff[scope].changed.each do |change|
        changes = []
        relevant_attributes = if opts[:attributes]
          opts[:attributes].dup
        else
          change[0].attributes.keys & change[1].attributes.keys
        end

        (1..optional_attributes.length).each do |i|
          if change[0][optional_attributes[i - 1]] ==
              change[1][optional_attributes[i - 1]]
            relevant_attributes.push(optional_attributes[i])
          else
            break
          end
        end
        relevant_attributes.each do |attribute|
          if change[0][attribute] != change[1][attribute]
            changes.push(
              attribute + ": " + human_readable_attribute(change[0], attribute) + " ↔ " +
                human_readable_attribute(change[1], attribute)
            )
          end
        end

        changed.push(change[0][opts[:key]] + " (" + changes.join(", ") + ")")
      end
      changed
    end

    def human_readable_attribute(object, attribute)
      value = object[attribute]

      case object
      when Machinery::SystemFile
        value = number_to_human_size(value) if attribute == "size"
      end

      value.to_s
    end

    def diffable_unmanaged_files
      return @diffable_unmanaged_files if @diffable_unmanaged_files

      return [] if !@diff["unmanaged_files"].try(:only_in1).try(:files) ||
          !@diff["unmanaged_files"].try(:only_in2).try(:files)

      files_in_1 = @diff["unmanaged_files"].only_in1.files.select(&:file?).map(&:name)
      files_in_2 = @diff["unmanaged_files"].only_in2.files.select(&:file?).map(&:name)

      @diffable_unmanaged_files = files_in_1 & files_in_2
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

  helpers Helpers

  get "/descriptions/:id/files/:scope/*" do
    description = SystemDescription.load(params[:id], settings.system_description_store)
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

  get "/compare/:a/:b" do
    @description_a = SystemDescription.load(params[:a], settings.system_description_store)
    @description_b = SystemDescription.load(params[:b], settings.system_description_store)

    @meta = {}
    @diff = {}

    Inspector.all_scopes.each do |scope|
      if @description_a[scope] && @description_b[scope]
        @diff[scope] = Comparison.compare_scope(@description_a, @description_b, scope)
      elsif @description_a[scope] || @description_b[scope]
        @meta[:uninspected] ||= Hash.new

        if !@description_a[scope]
          @meta[:uninspected][@description_a.name] ||= Array.new
          @meta[:uninspected][@description_a.name] << scope
        end
        if !@description_b[scope]
          @meta[:uninspected][@description_b.name] ||= Array.new
          @meta[:uninspected][@description_b.name] << scope
        end
      end
    end

    haml File.read(File.join(Machinery::ROOT, "html/comparison.html.haml"))
  end

  get "/compare/:a/:b/files/:scope/*" do
    description1 = SystemDescription.load(params[:a], settings.system_description_store)
    description2 = SystemDescription.load(params[:b], settings.system_description_store)
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
    @description = SystemDescription.load(params[:id], settings.system_description_store)

    diffs_dir = @description.scope_file_store("analyze/config_file_diffs").path
    if @description.config_files && diffs_dir
      # Enrich description with the config file diffs
      @description.config_files.files.each do |file|
        path = File.join(diffs_dir, file.name + ".diff")
        file.diff = diff_to_object(File.read(path)) if File.exists?(path)
      end
    end

    haml File.read(File.join(Machinery::ROOT, "html/index.html.haml"))
  end
end
