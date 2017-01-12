# -*- encoding: utf-8 -*-

# Copyright (c) 2013-2016 SUSE LLC
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
  s.name        = "machinery-tool"
  s.version     = Machinery::VERSION
  s.license     = "GPL-3.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["SUSE"]
  s.email       = ["machinery@lists.suse.com"]
  s.homepage    = "http://machinery-project.org"
  s.summary     = "Systems management toolkit"
  s.description = "Machinery is a systems management toolkit for Linux. It supports configuration discovery, system validation, and service migration. It's based on the idea of a universal system description."
  s.extensions = ["machinery-helper/Rakefile"]

  s.required_ruby_version = '>= 2.0.0'
  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "cheetah", "~>0.4"
  s.add_dependency "abstract_method", "~>1.2"
  s.add_dependency "builder", "~>3.2"
  s.add_dependency "gli", "~>2.11"
  s.add_dependency "json-schema", "~> 2.2.4"
  s.add_dependency "haml", "~> 4.0"
  s.add_dependency "kramdown", "~> 1.3"
  s.add_dependency "tilt", "~> 2.0"
  s.add_dependency "sinatra", "~> 1.4"
  s.add_dependency "mimemagic", "~> 0.3"
  s.add_dependency "diffy", "~> 3.0"

  s.files        = Dir[
    "lib/**/*.rb",
    "plugins/**/*",
    "workload_mapper/**/*",
    "bin/*",
    "filters/*",
    "man/generated/machinery.1.gz",
    "man/generated/machinery.1.html",
    "NEWS",
    "COPYING",
    "inspect_helpers/*",
    "export_helpers/*",
    "schema/**/*",
    "html/**/*",
    "machinery-helper/*.go",
    "machinery-helper/Rakefile",
    "machinery-helper/README.md",
    "tools/helper_builder.rb",
    "tools/go.rb",
    ".git_revision",
    "manual/**/*"
  ]
  s.executables  = "machinery"
  s.require_path = "lib"

  s.add_development_dependency "ronn", ">=0.7.3"
  s.add_development_dependency "rake"
  s.add_development_dependency "packaging_rake_tasks"
end
