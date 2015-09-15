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

class EnvironmentInspector < Inspector
  has_priority 5

  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(_filter = nil, _options = {})
    environment = EnvironmentScope.new

    environment.locale = get_locale

    @description.environment = environment
  end

  private

  def get_locale
    output = nil
    begin
      output = @system.run_command("locale", "-a", stdout: :capture)
      output.encode!("UTF-16be", invalid: :replace, undef: :replace, replace: "?").encode!("UTF-8")
    rescue
      return "C"
    end

    all_locales = output.split
    locale = ["en_US.utf8"].find { |l| all_locales.include?(l) }

    locale || "C"
  end
end
