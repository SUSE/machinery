#!/usr/bin/python
# Copyright (c) 2013-2021 SUSE LLC
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

use_yum = True
try:
    import yum
except ModuleNotFoundError:
    import dnf
    import libdnf
    use_yum = False

try:
  import json
except:
  import simplejson as json


repositories = []
if use_yum:
    yb = yum.YumBase()

    for repo in yb.repos.sort():
        repo_dict = dict()
        repo_dict["alias"] = repo.id
        repo_dict["name"] = repo.name
        repo_dict["type"] = "rpm-md"
        repo_dict["url"] = repo.baseurl or []
        repo_dict["mirrorlist"] = repo.mirrorlist or ""
        repo_dict["enabled"] = repo.enabled
        repo_dict["gpgcheck"] = repo.gpgcheck
        repo_dict["gpgkey"] = repo.gpgkey
        repositories.append(repo_dict)
else:
    db = dnf.Base()
    db.read_all_repos()

    # TODO(gyee): dnf has a lot more attributes. Should we get them all or just
    # need to be in parady with yum?
    #
    # FWIW, a typical dnf repo looks like this:
    #
    # [plus-source]
    # bandwidth: 0
    # baseurl: http://vault.centos.org/$contentdir/8/centosplus/Source/
    # cachedir: /var/tmp/dnf-centos-lb5ndf5p
    # cost: 1000
    # countme: 0
    # deltarpm: 1
    # deltarpm_percentage: 75
    # enabled: 0
    # enabled_metadata: 
    # enablegroups: 1
    # exclude: 
    # excludepkgs: 
    # fastestmirror: 0
    # gpgcheck: 1
    # gpgkey: file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
    # includepkgs: 
    # ip_resolve: whatever
    # max_parallel_downloads: 3
    # mediaid: 
    # metadata_expire: 172800
    # metalink: 
    # minrate: 1000
    # mirrorlist: 
    # module_hotfixes: 0
    # name: CentOS Linux 8 - Plus - Source
    # password: 
    # priority: 99
    # protected_packages: dnf, dnf, systemd, systemd-udev, yum, sudo, setup,
    #                     dnf, systemd, systemd-udev, yum, sudo, setup
    # proxy: 
    # proxy_auth_method: any
    # proxy_password: 
    # proxy_username: 
    # repo_gpgcheck: 0
    # retries: 10
    # skip_if_unavailable: 0
    # sslcacert: 
    # sslclientcert: 
    # sslclientkey: 
    # sslverify: 1
    # throttle: 0
    # timeout: 30
    # type: 
    # user_agent: libdnf (CentOS Linux 8; generic; Linux.x86_64)
    # username: 
    #
    # see the dnf source code here:
    # https://github.com/rpm-software-management/dnf/tree/master/dnf
    #
    for name, repo in db.repos.items():
        repo_dict = dict()
        repo_dict["alias"] = name
        repo_dict["name"] = repo.name
        repo_dict["type"] = "rpm-md"

        # NOTE(gyee): because of
        # https://bugzilla.redhat.com/show_bug.cgi?id=1661814
        # baseurl can potentially be VectorString instead of array of
        # strings.
        if isinstance(repo.baseurl, libdnf.module.VectorString):
            baseurl_str = str(repo.baseurl).strip().replace("'", '"')
            repo_dict["url"] = json.loads(baseurl_str) if baseurl_str else []
        else:
            repo_dict["url"] = repo.baseurl or []
        repo_dict["mirrorlist"] = repo.mirrorlist or []
        repo_dict["enabled"] = repo.enabled
        repo_dict["gpgcheck"] = repo.gpgcheck

        # NOTE(gyee): because of
        # https://bugzilla.redhat.com/show_bug.cgi?id=1661814
        # gpgkey can potentially be VectorString instead of array of
        # strings.
        if isinstance(repo.gpgkey, libdnf.module.VectorString):
            gpgkey_str = str(repo.gpgkey).strip().replace("'", '"')
            repo_dict["gpgkey"] = json.loads(gpgkey_str) if gpgkey_str else []
        else:
            repo_dict["gpgkey"] = repo.gpgkey or []
        repositories.append(repo_dict)

print(json.dumps(repositories))
