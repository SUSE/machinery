# -*- coding: utf-8 -*-
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

# Rack::TryStatic was taken from the rack-contrib repository (https://github.com/rack/rack-contrib)
module Rack
  class TryStatic
    def initialize(app, options)
      @app = app
      @try = ["", *options[:try]]
      @static = ::Rack::Static.new(->(_) { [404, {}, []] }, options)
    end

    def call(env)
      orig_path = env["PATH_INFO"]
      found = nil
      @try.each do |path|
        resp = @static.call(env.merge!("PATH_INFO" => orig_path + path))
        break if !(403..405).cover?(resp[0]) && found = resp
      end
      found || @app.call(env.merge!("PATH_INFO" => orig_path))
    end
  end
end


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

    def repository_changes
      klass = @diff["repositories"].changed.first.first.class
      changed_elements("repositories", attributes: klass.attributes, key: klass.key)
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

        changed.push(
          id:       change[0][opts[:key]],
          change:   "(" + changes.join(", ") + ")",
          diffable: change[0].is_a?(UnmanagedFile) && change[0].is_a?(UnmanagedFile) &&
            change[0].file? && change[1].file? &&
            @diff[scope].try(:common).try(:attributes).try(:[], "extracted")
        )
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

  # Serve the 'manual/site' directory under /site using Rack::TryStatic
  use Rack::TryStatic,
    root: File.join(Machinery::ROOT, "manual"),
    urls: %w[/site],
    try: ["index.html"]


  get "/descriptions/:id/files/:scope/*" do
    description = SystemDescription.load(params[:id], settings.system_description_store)
    filename = File.join("/", params["splat"].first)

    file = description[params[:scope]].find { |f| f.name == filename }

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

  get "/" do
    descriptions = settings.system_description_store.list
    @all_descriptions = Hash.new

    descriptions.each do |name|
      scopes = []
      begin
        system_description = SystemDescription.load(
          name, settings.system_description_store, skip_validation: true
        )
        @all_descriptions[name] = Hash.new
        @all_descriptions[name]["date"] = system_description.latest_update
        @all_descriptions[name]["host"] = system_description.host
        system_description.scopes.each do |scope|
          entry = Machinery::Ui.internal_scope_list_to_string(scope)
          if SystemDescription::EXTRACTABLE_SCOPES.include?(scope)
            if system_description.scope_extracted?(scope)
              entry += " (extracted)"
            else
              entry += " (not extracted)"
            end
          end
          scopes << entry
        end
        @all_descriptions[name]["scopes"] = scopes
      rescue Machinery::Errors::SystemDescriptionIncompatible,
             Machinery::Errors::SystemDescriptionError => e
        @errors ||= Array.new
        @errors.push(e)
      end
    end

    haml File.read(File.join(Machinery::ROOT, "html/landing_page.html.haml"))
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
      @description.config_files.each do |file|
        path = File.join(diffs_dir, file.name + ".diff")
        file.diff = diff_to_object(File.read(path)) if File.exists?(path)
      end
    end

    haml File.read(File.join(Machinery::ROOT, "html/index.html.haml"))
  end
end
