# -*- encoding: utf-8 -*-

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

require File.expand_path("../lib/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "machinery"
  s.version     = Machinery::VERSION
  s.license     = "GPL-3.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["SUSE"]
  s.email       = ["machinery@lists.suse.com"]
  s.homepage    = "https://github.com/SUSE/machinery/"
  s.summary     = "Systems management toolkit"
  s.description = "Machinery is a systems management toolkit for Linux. It supports configuration discovery, system validation, and service migration. It's based on the idea of a universal system description."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "machinery"

  s.add_dependency "cheetah", ">=0.4.0"
  s.add_dependency "json", ">=1.8.0"
  s.add_dependency "abstract_method", ">=1.2.1"
  s.add_dependency "nokogiri", ">=1.6.0"
  s.add_dependency "gli", "~> 2.11.0"
  s.add_dependency "json-schema", "~> 2.2.4"
  s.add_dependency "haml", "~> 4.0.5"
  s.add_dependency "kramdown", "~> 1.3.3"
  s.add_dependency "tilt", ">= 2.0"

  s.files        = Dir[
    "lib/**/*.rb",
    "plugins/**/*",
    "bin/*",
    "man/generator/machinery.1.gz",
    "man/generator/machinery.1.html",
    "NEWS",
    "COPYING",
    "helpers/*",
    "kiwi_helpers/*",
    "schema/**/*",
    "html/**/*"
  ]
  s.executables  = "machinery"
  s.require_path = "lib"

  s.add_development_dependency "ronn", ">=0.7.3"
  s.add_development_dependency "rake"
  s.add_development_dependency "packaging_rake_tasks"
end
