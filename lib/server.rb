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
    include HamlHelpers
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

    def offset_class(first_col)
      return "" if first_col
      "col-md-offset-6"
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
  end

  helpers Helpers

  # Serve the 'manual/site' directory under /site using Rack::TryStatic
  use Rack::TryStatic,
    root: File.join(Machinery::ROOT, "manual"),
    urls: %w[/site],
    try: ["index.html"]

  enable :sessions

  get "/descriptions/:id/files/:scope/*" do
    description = Machinery::SystemDescription.load(params[:id], settings.system_description_store)
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

  def all_descriptions
    check_session_for_error
    descriptions = settings.system_description_store.list
    @all_descriptions = Hash.new

    descriptions.each do |name|
      scopes = []
      begin
        system_description = Machinery::SystemDescription.load(
          name, settings.system_description_store, skip_validation: true
        )
        @all_descriptions[name] = Hash.new
        @all_descriptions[name]["date"] = system_description.latest_update
        @all_descriptions[name]["host"] = system_description.host
        system_description.scopes.each do |scope|
          entry = Machinery::Ui.internal_scope_list_to_string(scope)
          if Machinery::SystemDescription::EXTRACTABLE_SCOPES.include?(scope)
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
  end

  get "/" do
    all_descriptions

    haml File.read(File.join(Machinery::ROOT, "html/homepage.html.haml"))
  end

  get "/fonts/:font" do
    File.read(File.join(Machinery::ROOT, "html/assets/fonts/#{params[:font]}"))
  end

  get "/compare/:a/:b" do
    all_descriptions

    @description_a = Machinery::SystemDescription.load(
      params[:a], settings.system_description_store
    )
    @description_b = Machinery::SystemDescription.load(
      params[:b], settings.system_description_store
    )

    @meta = {}
    @diff = {}

    Machinery::Inspector.all_scopes.each do |scope|
      if @description_a[scope] && @description_b[scope]
        @diff[scope] = Machinery::Comparison.compare_scope(@description_a, @description_b, scope)
      elsif @description_a[scope] || @description_b[scope]
        @meta[:uninspected] ||= Hash.new

        unless @description_a[scope]
          @meta[:uninspected][@description_a.name] ||= Array.new
          @meta[:uninspected][@description_a.name] << scope
        end
        unless @description_b[scope]
          @meta[:uninspected][@description_b.name] ||= Array.new
          @meta[:uninspected][@description_b.name] << scope
        end
      end
    end

    haml File.read(File.join(Machinery::ROOT, "html/comparison.html.haml"))
  end

  get "/compare/:a/:b/files/:scope/*" do
    description1 = Machinery::SystemDescription.load(params[:a], settings.system_description_store)
    description2 = Machinery::SystemDescription.load(params[:b], settings.system_description_store)
    filename = File.join("/", params["splat"].first)

    begin
      diff = Machinery::FileDiff.diff(description1, description2, params[:scope], filename)
    rescue Machinery::Errors::BinaryDiffError
      status 406
      return "binary file"
    end

    diff.to_s(:html)
  end

  get "/:id" do
    all_descriptions

    begin
      @description = Machinery::SystemDescription.load(
        params[:id], settings.system_description_store
      )
    rescue Machinery::Errors::SystemDescriptionNotFound => e
      session[:error] = e.to_s
      redirect "/"
    rescue Machinery::Errors::SystemDescriptionIncompatible, \
           Machinery::Errors::SystemDescriptionError => e
      @error = e
      haml File.read(File.join(Machinery::ROOT, "html/exception.html.haml"))
    else
      @description.load_existing_diffs
      haml File.read(File.join(Machinery::ROOT, "html/index.html.haml"))
    end
  end

  private

  def check_session_for_error
    if session[:error]
      @errors ||= Array.new
      @errors.push(session[:error])
      session.clear
    end
  end

  def render_exception_title
    case @error
    when Machinery::Errors::SystemDescriptionIncompatible
      return "System Description incompatible!"
    when Machinery::Errors::SystemDescriptionError
      return "System Description broken!"
    end
  end
end
