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

require "nokogiri"

class RepositoriesInspector < Inspector
  def inspect(system, description, options = {})
    system.check_requirement("zypper", "--version")

    begin
      xml = system.run_command(
        "zypper", "--non-interactive", "--xmlout", "repos", "--details", :stdout => :capture
      )
      details = system.run_command(
        "zypper", "--non-interactive", "repos", "--details", :stdout => :capture
      ).split("\n").select { |l| l =~ /\A# +\| |\A *\d+ \| / }.
        map { |l| l.split("|").map(&:strip) }
    rescue Cheetah::ExecutionFailed => e
      if e.status.exitstatus == 6
        description.repositories = RepositoriesScope.new([])
        return "Found 0 repositories."
      else
        raise e
      end
    end

    if !details.empty?
      # parse and remove header
      idx_prio = details.first.index("Priority")
      idx_alias = details.first.index("Alias")
      details.shift

      prio = {}
      details.each_with_index do |entry,idx|
        prio[entry[idx_alias]] = entry[idx_prio].to_i
      end

      credentials = {}
      credential_dir = "/etc/zypp/credentials.d/"
      credential_files = system.run_command(
        "bash", "-c",
        "test -d '#{credential_dir}' && ls -1 '#{credential_dir}' || echo ''",
        :stdout => :capture
      )
      credential_files.split("\n").each do |f|
        content = system.run_command(
          "cat", "/etc/zypp/credentials.d/#{f}", :stdout => :capture
        )
        content.match(/username=(\w*)\npassword=(\w*)/)
        credentials[f] = {
          username: $1,
          password: $2
        }
      end

      reps = Nokogiri::XML(xml).xpath("/stream/repo-list/repo")
      summary = "Found #{reps.count} repositories."
      result = reps.map do |rep|
        pri_value = rep["priority"] ? rep["priority"].to_i : prio[rep["alias"]]

        # NCC
        rep.at_xpath("./url").text.match(/\?credentials=(\w*)/)
        cred_value = $1
        if cred_value && credentials[cred_value]
          username = credentials[cred_value][:username]
          password = credentials[cred_value][:password]
        end

        # SCC
        rep.at_xpath("./url").text.match(/(https:\/\/updates.suse.com\/SUSE\/)/)
        scc_url = $1
        cred_value = "SCCcredentials"
        if scc_url && credentials[cred_value]
          username = credentials[cred_value][:username]
          password = credentials[cred_value][:password]
        end

        repository = Repository.new(
          alias:       rep["alias"],
          name:        rep["name"],
          type:        rep["type"],
          url:         rep.at_xpath("./url").text,
          enabled:     rep["enabled"] == "1",
          autorefresh: rep["autorefresh"] == "1",
          gpgcheck:    rep["gpgcheck"] == "1",
          priority:    pri_value
        )
        if username && password
          repository[:username] = username
          repository[:password] = password
        end
        repository
      end.sort_by(&:name)
    else
      result = []
      summary = "Found 0 repositories."
    end

    description.repositories = RepositoriesScope.new(result)
    summary
  end
end
