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

require_relative "../../lib/machinery"

# Suppress phantomjs-gem warning about phantomjs not being installed system-wide
require "phantomjs"
module Phantomjs
  class Platform
    def self.system_phantomjs_path
      `which phantomjs 2> /dev/null`.delete("\n")
    rescue
    end
  end
end

require "byebug"
require "rspec-steps"
require "capybara/rspec"
require "capybara/poltergeist"
require "phantomjs/poltergeist"
require "tilt/haml"
require_relative "../support/system_description_factory"
require "given_filesystem/spec_helpers"

RSpec.configure do |config|
  config.include SystemDescriptionFactory
end

Capybara.configure do |config|
  Server.set :public_folder, File.join(Machinery::ROOT, "html")
  config.app = Server

  config.default_driver = :poltergeist
end

def get_position(selector)
  pos = page.driver.evaluate_script <<-EOS
    function() {
      var elem1 = document.querySelector('#{selector}');
      var rect1 = elem1.getBoundingClientRect();
      return [rect1.left, rect1.top];
    }();
    EOS
  pos
end
