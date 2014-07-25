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

require_relative "spec_helper"


describe ShowTask, "#show" do
  let(:show_task) { ShowTask.new }
  let(:system_description) { SystemDescription.new("foo") }
  let(:description_with_packages) {
    json = <<-EOF
      {
        "packages": []  
      }
    EOF
    SystemDescription.from_json("name", json)
  }


  it "runs all renderers when no scope is given" do
    expect(Renderer).to receive(:all) { [] }

    show_task.show(system_description, nil, :no_pager => true)
  end

  it "runs the proper renderer when a scope is given" do
    renderer = double
    expect(renderer).to receive(:render).and_return("bar")
    expect(Renderer).to receive(:for).with("foo").and_return(renderer)

    show_task.show(system_description, ["foo"], :no_pager => true)
  end

  it "prints scopes missing from the system description" do
    scope = "packages"
    expect($stdout).to receive(:puts) { |s|
      expect(s).to include("requested scopes were not inspected")
      expect(s).to include("packages")
    }
    show_task.show(system_description, [scope], :no_pager => true)
  end

  it "does not show a message about missing scopes if there are none" do
    scope = "packages"
    expect($stdout).to receive(:puts) { |s|
      expect(s).not_to include("requested scopes were not inspected")
      expect(s).not_to include("packages")
    }
    show_task.show(description_with_packages, [scope], :no_pager => true)
  end

  it "throws an error when renderer does not exist" do
    expect {
      show_task.show(system_description, ["unknown"])
    }.to raise_error(Machinery::UnknownRendererError)
  end
end
