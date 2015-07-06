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

class Comparison
  attr_accessor :name1, :name2, :only_in1, :only_in2, :changed, :common, :store, :scope

  def self.compare_scope(description1, description2, scope)
    result = new
    result.store = description1.store
    result.scope = scope
    result.name1 = description1.name
    result.name2 = description2.name

    if !description1[scope]
      result.only_in2 = description2[scope]
    elsif !description2[scope]
      result.only_in1 = description1[scope]
    else
      result.only_in1, result.only_in2, result.changed, result.common =
        description1[scope].compare_with(description2[scope])
    end

    result
  end

  def as_description(which)
    case which
    when :one
      name = name1
      data = only_in1
    when :two
      name = name2
      data = only_in2
    when :common
      name = "common"
      data = common
    else
      raise "'which' has to be :one, :two or :common"
    end

    SystemDescription.new(name, store, scope => data)
  end

  def as_json
    json = {}
    json["only_in1"] = only_in1.as_json if only_in1
    json["only_in2"] = only_in2.as_json if only_in2
    if changed
      json["changed"] = changed.map { |elements| [elements.first.as_json, elements.last.as_json] }
    end
    json["common"] = common.as_json if common

    json
  end
end
