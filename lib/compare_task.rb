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
    output = render_comparison(description1, description2, scopes, options)

    Machinery::Ui.puts output
  end

  def render_comparison(description1, description2, scopes, options = {})
    output = ""
    identical = true
    common_scopes = false
    store = description1.store
    scopes.each do |scope|
      if description1[scope] && description2[scope]
        comparison = description1[scope].compare_with(description2[scope])

        partial_description1 = SystemDescription.new(
          description1.name,
          store,
          scope => comparison[0]
        )

        partial_description2 = SystemDescription.new(
          description2.name,
          store,
          scope => comparison[1]
        )

        partial_description_common = SystemDescription.new(
          "common",
          store,
          scope => comparison[2]
        )

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

    output
  end
end
