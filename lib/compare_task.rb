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

class CompareTask
  def compare(description1, description2, scopes, options = {})
    if options[:show_html]
      render_html_comparison(description1, description2, scopes, options)
    else
      output = render_comparison(description1, description2, scopes, options)

      Machinery::Ui.puts output
    end
  end

  def render_html_comparison(description1, description2, scopes, options)
    diff = {
      meta: {
        description_a: description1.name,
        description_b: description2.name,
      }
    }

    scopes.each do |scope|
      if description1[scope] && description2[scope]
        comparison = description1[scope].compare_with(description2[scope])
        diff[scope] = comparison.map { |scope| scope.as_json if scope }
      end
    end

    target = File.join(Machinery::DEFAULT_CONFIG_DIR, "html-comparison")
    FileUtils.rm_r(target) if Dir.exists?(target)
    FileUtils.mkdir_p(target)

    Html.generate_comparison(diff, target)
    LoggedCheetah.run("xdg-open", File.join(target, "index.html"))
  end

  def render_comparison(description1, description2, scopes, options = {})
    output = ""
    identical = true
    identical_scopes = []
    common_scopes = false
    scopes.each do |scope|
      if description1[scope] && description2[scope]
        comparison = Comparison.compare_scope(description1, description2, scope)

        output += Renderer.for(scope).render_comparison(comparison, options)

        if comparison.only_in1 || comparison.only_in2 || comparison.changed
          identical = false
        else
          identical_scopes << scope
        end
        common_scopes = true
      else
        output += Renderer.for(scope).render_comparison_missing_scope(
          description1, description2
        )
        identical = false if description1[scope] || description2[scope]
      end
    end
    output = "Compared descriptions are identical.\n" + output if identical && common_scopes

    if !identical_scopes.empty?
      phrase = Machinery::pluralize(identical_scopes.count, "scope is", "scopes are")
      output += "Following #{phrase} identical in both descriptions: " + identical_scopes.join(",")
    end

    output
  end
end
