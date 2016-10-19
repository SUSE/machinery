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

require_relative "spec_helper"

describe Machinery::Scope do
  class Machinery::SimpleScope < Machinery::Object
    include Machinery::Scope
  end
  class Machinery::MoreComplexScope < Machinery::Object
    include Machinery::Scope
    hidden_scope

    has_property :foo, class: Machinery::Object
  end

  subject { Machinery::SimpleScope.new }

  it "provides accessors for timestamp and hostname to a simple scope" do
    mytime = Time.now.utc.iso8601
    host = "192.168.122.216"

    expect(subject.meta).to be(nil)

    subject.set_metadata(mytime, host)

    t = Time.utc(subject.meta.modified)
    expect(t.utc?).to eq(true)
    expect(subject.meta.modified).to eq(mytime)
    expect(subject.meta.hostname).to eq(host)
  end

  describe ".scope_name" do
    example { expect(Machinery::SimpleScope.scope_name).to eq("simple") }
    example { expect(Machinery::MoreComplexScope.scope_name).to eq("more_complex") }
  end

  describe "#scope_name" do
    example { expect(subject.scope_name).to eq("simple") }
    example { expect(Machinery::MoreComplexScope.new.scope_name).to eq("more_complex") }
  end

  it "lists all scopes" do
    expect(Machinery::Scope.all_scopes).to include(Machinery::SimpleScope)
    expect(Machinery::Scope.all_scopes).to include(Machinery::MoreComplexScope)
  end

  it "lists only scopes" do
    Machinery::Scope.all_scopes.each do |scope|
      expect(scope.included_modules).to include(Machinery::Scope)
    end
  end

  describe "#is_extractable?" do
    before(:each) do
      stub_const("Machinery::SystemDescription::EXTRACTABLE_SCOPES", ["simple"])
    end

    example { expect(subject.is_extractable?).to be(true) }
    example { expect(Machinery::MoreComplexScope.new.is_extractable?).to be(false) }
  end

  describe "#for" do
    let(:scope_file_store) { double }

    it "returns simple scope" do
      scope = Machinery::Scope.for("simple", {}, scope_file_store)
      expect(scope).to be_a(Machinery::SimpleScope)
      expect(scope.scope_file_store).to eq(scope_file_store)
    end

    it "returns complex scope" do
      scope = Machinery::Scope.for("more_complex", {}, scope_file_store)
      expect(scope).to be_a(Machinery::MoreComplexScope)
      expect(scope.scope_file_store).to eq(scope_file_store)
    end

    it "sets the scope in the created objects" do
      hash = {
        foo: {
          a: 1
        }
      }
      scope = Machinery::Scope.for("more_complex", hash, scope_file_store)

      expect(scope.foo.scope).to eq(scope)
    end
  end

  describe ".extract_changed_elements" do
    before(:each) do
      @a = [
        Machinery::Object.new(name: "foo", value: 1),
        Machinery::Object.new(name: "bar", value: 1)
      ]
      @b = [
        Machinery::Object.new(name: "foo", value: 2),
        Machinery::Object.new(name: "baz", value: 2)
      ]

      @changed = Machinery::Scope.extract_changed_elements(@a, @b, :name)
    end

    it "removes the changed elements from the scopes" do
      expect(@a.length).to eq(1)
      expect(@b.length).to eq(1)
    end

    it "detects the changed elements" do
      expect(@changed).to eq(
        [
          [
            Machinery::Object.new(name: "foo", value: 1),
            Machinery::Object.new(name: "foo", value: 2)
          ]
        ]
      )
    end
  end
end
