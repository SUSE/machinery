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

require File.expand_path('../../../tools/spec_template.rb', __FILE__)

describe SpecTemplate do
  let(:version)  { "0.16.0" }
  let(:gemspec) {
    spec = Gem::Specification.new do |s|
      s.name = "machinery"
      s.version = "0.16.0"
      s.summary = "Systems management toolkit"
      s.add_dependency "thor", ">=0.14.0"
      s.add_dependency "gli", "~> 2.11.0"
      s.add_development_dependency "ronn", ">=0.7.3"
      s.add_development_dependency "rake"
  end
  }
  let(:template) { SpecTemplate.new(version, gemspec) }

  describe "#build_requires" do
    it "returns the build requirements" do
      expect(template.build_requires).to include(
        {
          name: "thor",
          operator: ">=",
          version: Gem::Version.new("0.14.0")
        }
      )
    end

    it "returns build requirements with multiple versions" do
      expect(template.build_requires).to include(
        {
          name: "gli",
          operator: ">=",
          version: Gem::Version.new("2.11.0")
        }
      )
      expect(template.build_requires).to include(
        {
          name: "gli",
          operator: "<=",
          version: Gem::Version.new("2.12.0")
        }
      )
    end
  end
end
