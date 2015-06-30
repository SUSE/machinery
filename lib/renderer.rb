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

# Renderer is the base class for all text renderer plugins
#
# It defines methods for rendering data which will be called from the
# specialized content methods in the subclasses.
#
# Subclasses can define the output for the `show` and `compare` commands using
# the following `content` methods:
#
# For `machinery show`:
# [content] (required) Defines the output for a scope in `machinery show`
#
# For `machinery compare`:
# [compare_content_only_in] Defines the output of the "only in x" sections. The
#                           default behavior is to fall back to `content`.
# [compare_content_common]  Defines the output of the "in both" section. The
#                           default behavior is to fall back to `content`.
# [compare_content_changed] Defines the output of the "in both with changed
#                           attributes" section for scopes where this is
#                           supported.
#
# The names of the subclasses are 1:1 mappings of the scope areas, e.g.
# the PackagesRenderer class would be used for rendering when the user
# specifies "--scope=packages".
#
# The rendering methods are:
# def heading(s)   - Render a heading
# def puts(s)      - Print one line
# def list(name)   - Start a list. This method takes a block where the items are
#                    created.
# def item(s)      - Print a list item
#
# Accordingly a simple renderer for the "packages" scope could look like this:
#
# class PackagesRenderer < Renderer
#   def content(description)
#     return if description.packages.empty?
#
#     list "Packages" do
#       description.packages.each do |p|
#         item "#{p.name} (#{p.version})"
#       end
#     end
#   end
# end
class Renderer

  class InvalidStructureError < StandardError; end

  attr_accessor :system_description
  attr_accessor :buffer

  abstract_method :content
  abstract_method :compare_content_changed

  @@renderers = []

  class << self
    def inherited(klass)
      @@renderers << klass
    end

    def all
      @@renderers.map { |renderer| renderer.new }
    end

    def for(scope)
      class_name = "#{scope.split("_").map(&:capitalize).join}Renderer"

      if Object.const_defined?(class_name)
        Object.const_get(class_name).new
      end
    end
  end

  def scope
    # Return the un-camelcased name of the inspector,
    # e.g. "foo_bar" for "FooBarInspector"
    scope = self.class.name.match(/^(.*)Renderer$/)[1]
    scope.gsub(/([^A-Z])([A-Z])/, "\\1_\\2").downcase
  end

  # Renders one system description using the specialized `content` method
  def render(system_description, options = {})
    @options = options
    @buffer = ""
    @indent = 2
    @stack = []

    if system_description[scope]
      header = display_name
      meta = system_description[scope].meta

      if meta
          header += " [#{meta.hostname}]"
          date = Time.parse(meta.modified).localtime
          date_human = date.strftime "%Y-%m-%d %H:%M:%S"
          header += " (#{date_human})"
      end

      heading(header)
    end

    content(system_description)

    @buffer += "\n" unless @buffer.empty? || @buffer.end_with?("\n\n")

    @buffer
  end

  # Renders the result of a comparison of two system descriptions. The arguments to that method
  # are three SystemDescriptions:
  #
  # [description1] contains all elements that are only present in description1
  # [description2] contains all elements that are only present in description2
  # [description_common] contains all elements that are present in both descriptions
  #
  # The actual rendering is done using the `content_comparison` method. The default behaviour
  # of that method is to
  #
  # * render description1 (the actual rendering happens in `content_only_in`)
  # * render description2 (the actual rendering happens in `content_only_in`)
  # * render description_common (the actual rendering happens in `content_common`)
  #
  # Both `content_only_in` and `content_common` fall back to the `content` method by default.
  #
  # When necessary the default behavior can be overridden by specializing either the outer
  # `content_comparison` method and/or `content_only_in` and `content_common`.
  def render_comparison(description1, description2, changed_elements, description_common,
      options = {})
    @options = options
    @buffer = ""
    @indent = 0
    @stack = []

    show_heading = if options[:show_all]
      description1[scope] || description2[scope] || changed_elements || description_common[scope]
    else
      description1[scope] || description2[scope] || changed_elements
    end

    heading(display_name) if show_heading

    render_comparison_only_in(description1)
    render_comparison_only_in(description2)
    if changed_elements
      render_comparison_changed(description1.name, description2.name, changed_elements)
    end
    render_comparison_common(description_common) if @options[:show_all]
    @buffer
  end

  def render_comparison_only_in(description)
    return if !description[scope]

    puts "Only in '#{description.name}':"
    indent { compare_content_only_in(description) }
    @buffer += "\n" unless @buffer.empty? || @buffer.end_with?("\n\n")
  end

  def render_comparison_changed(name1, name2, changed_elements)
    puts "In both with different attributes ('#{name1}' <> '#{name2}'):"
    indent { compare_content_changed(changed_elements) }
    @buffer += "\n" unless @buffer.empty? || @buffer.end_with?("\n\n")
  end

  def render_comparison_common(description)
    return if !description[scope]

    puts "Common to both systems:"
    indent { compare_content_common(description) }
    @buffer += "\n" unless @buffer.empty? || @buffer.end_with?("\n\n")
  end

  def compare_content_only_in(description)
    content(description)
  end

  def compare_content_common(description)
    content(description)
  end

  def render_comparison_missing_scope(description1, description2)
    @buffer = ""
    @indent = 0
    @stack = []
    missing_descriptions = Array.new

    if !description1[scope]
      missing_descriptions << description1.name
    end
    if !description2[scope]
      missing_descriptions << description2.name
    end

    if missing_descriptions.count == 1
      @buffer += "# #{display_name}\n"
      indent { puts "Unable to compare, no data in '#{missing_descriptions.join("', '")}'" }
    end
    @buffer += "\n" unless @buffer.empty? || @buffer.end_with?("\n\n")

    @buffer
  end

  protected

  def heading(s)
    @buffer += "# #{s}\n\n"
  end

  def puts(s)
    print_indented "#{s}"
  end

  def list(name = nil, &block)
    unless block_given?
      raise InvalidStructureError.new(
        "'list' was called without a block"
      )
    end

    @stack << :list


    if name && !name.empty?
      print_indented "#{name}:"
      indent do
        block.call
      end
    else
      block.call
    end
    @buffer += "\n" unless @buffer.end_with?("\n\n")

    @stack.pop
  end

  def item(s, &block)
    unless @stack.last == :list
      raise InvalidStructureError.new(
        "'item' was called outside of a list block"
      )
    end

    print_indented "* #{s}"

    if block_given?
      @stack << :item
      indent do
        block.call
      end
      @buffer += "\n"
      @stack.pop
    end
  end

  private

  def print_indented(s)
    s.split("\n").each do |line|
      @buffer += " " * @indent + line + "\n"
    end
  end

  def indent
    @indent += 2
    yield
    @indent -= 2
  end
end
