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

require "json"
require "net/http"
require "uri"

module ReleaseChecks
  def check
    check_tag
    check_jenkins_state("https://ci.opensuse.org/job/machinery-unit/lastStableBuild/api/json")
    check_jenkins_state("https://ci.opensuse.org/job/machinery-helper/lastStableBuild/api/json")
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

  def check_jenkins_state(jenkins_url)
    request = generate_request(jenkins_url)
    json = JSON.parse(get_response(request))

    actions = json["actions"].reject(&:empty?)
    last_revision_tested?(get_last_revision, get_tested_revision(actions))

    get_result(json["result"])
  end

  def get_response(request)
    response = http.request(request)
    if response.code != "200"
      fail "Could not download Jenkins state information. Abort."
    else
      response.body
    end
  end

  def generate_request(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    Net::HTTP::Get.new(uri.request_uri)
  end

  def get_result(response)
    result = response
    if result != "SUCCESS"
      fail "Current HEAD does not build successfully in Jenkins. Abort."
    end
    result
  end

  def get_tested_revision(actions)
    tested_revision = actions.find do |e|
      e.has_key?("lastBuiltRevision")
    end["lastBuiltRevision"]["SHA1"]
    tested_revision
  end

  def get_last_revision
    Cheetah.run("git", "rev-parse", "HEAD", stdout::capture).chomp
  end

  def last_revision_tested?(last_revision, tested_revision)
    if last_revision != tested_revision
      fail "Current HEAD (#{last_revision}) was not tested by Jenkins yet (#{tested_revision}). " /
        "Abort."
    end
  end
end
