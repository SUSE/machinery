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

require "json"
require "net/http"
require "uri"

module ReleaseChecks
  def check
    check_tag
    check_jenkins_state
  end

  private

  def fail(msg)
    puts msg
    exit 1
  end

  def check_tag
    Cheetah.run("git", "fetch", "--tags")
    existing_tag = Cheetah.run("git", "tag", "-l", @tag, :stdout => :capture)

    unless existing_tag.empty?
      fail "Tag #{@tag} already exists. Abort."
    end
  end

  def check_jenkins_state
    uri = URI.parse("https://ci.opensuse.org/job/machinery-unit/lastStableBuild/api/json")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    if response.code == "200"
      json = JSON.parse(response.body)

      actions = json["actions"].reject{ |h| h.empty? }

      last_revision = Cheetah.run("git", "rev-parse", "HEAD", :stdout => :capture).chomp
      tested_revision = actions.find do |e|
        e.has_key?("lastBuiltRevision")
      end["lastBuiltRevision"]["SHA1"]

      if last_revision != tested_revision
        fail "Current HEAD (#{last_revision}) was not tested by Jenkins yet (#{tested_revision}). Abort."
      end

      result = json["result"]
      if result != "SUCCESS"
        fail "Current HEAD does not build successfully in Jenkins. Abort."
      end
    else
      fail "Could not download Jenkins state information. Abort."
    end
  end
end
