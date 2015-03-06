#!/usr/bin/python
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

import yum
try:
  import json
except:
  import simplejson as json

yb = yum.YumBase()

repositories = []

for repo in yb.repos.sort():
  repo_dict = dict()
  repo_dict["alias"] = repo.id
  repo_dict["name"] = repo.name
  repo_dict["type"] = "rpm-md"
  if repo.baseurl:
    repo_dict["url"] = repo.baseurl[0]
  else:
    repo_dict["url"] = ""

  repo_dict["enabled"] = repo.enabled
  repo_dict["gpgcheck"] = repo.gpgcheck
  repo_dict["package_manager"] = "yum"
  repositories.append(repo_dict)

print(json.dumps(repositories))
