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

class CompareTask
  def compare(description1, description2, scopes, options = {})
    failed_scopes = []

    scopes.each do |scope|
      if !Renderer.for(scope)
        failed_scopes << scope
      end
    end

    if failed_scopes.length > 0
      raise Machinery::Errors::UnknownRenderer.new(
        "The following scopes are not supported: " \
        "#{Machinery::Ui.internal_scope_list_to_string(failed_scopes)}. " \
        "Valid scopes are: " \
          "#{Machinery::Ui.internal_scope_list_to_string(Inspector.all_scopes)}."
      )
    end

    output = ""
    identical = true
    common_scopes = false
    scopes.each do |scope|
      if description1[scope] && description2[scope]
        comparison = description1[scope].compare_with(description2[scope])

        partial_description1 = SystemDescription.new(
          description1.name,
          scope => comparison[0]
        )

        partial_description2 = SystemDescription.new(
          description2.name,
          scope => comparison[1]
        )

        partial_description_common = SystemDescription.new("common", scope => comparison[2])

        output += Renderer.for(scope).render_comparison(
          partial_description1,
          partial_description2,
          partial_description_common,
          options
        )

        if partial_description1[scope] || partial_description2[scope]
          identical = false
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

    Machinery::Ui.print_output(output, :no_pager => options[:no_pager])
  end
end
