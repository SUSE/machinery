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

class ManTask
  def self.compile_scope_documentation
    docs = Inspector.all_scopes.map do |scope|
      scope_doc = "* #{scope}\n\n"
      scope_doc += YAML.load_file(
        File.join(Machinery::ROOT, "plugins/#{scope}/#{scope}.yml")
      )[:description]
      scope_doc + "\n"
    end.join
    File.write("manual/docs/machinery_main_scopes.1.md", docs)
  end

  def man
    LocalSystem.validate_existence_of_package("man")
    system("man", man_path)
  end

  def man_path
    File.join(Machinery::ROOT, "man/generated/machinery.1.gz")
  end
end
