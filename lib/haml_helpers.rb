module HamlHelpers
  def render_partial(partial, locals = {})
    source = File.read(File.join(Machinery::ROOT, "html/partials/#{partial}.html.haml"))
    haml source, locals: locals
  end

  def render_scope(scope)
    render_partial scope, scope => @description[scope]
  end

  def scope_meta_info(scope)
    return "" unless @description[scope]

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
end
