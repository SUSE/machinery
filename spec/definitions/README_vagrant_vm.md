# Documentation for Vagrant VMs

The Vagrant virtual machines used for running the integration tests are
defined in `vagrant/Vagrantfile`. They get provisioned by inline shell scripts
that install additional software to prepare the systems for integration
tests.

By default the following VMs are defined:

## opensuse_leap

**Description**
This VM is the inspected system in our integration tests.

  **Based on box:** base_opensuse_leap_kvm<br>
  **Vagrant provider used:** libvirt<br>
  **User credentials:**<br>
    *User:* root, *Password:* vagrant<br>
    *User:* vagrant, *Password:* vagrant<br>
  **Memory:** 1024M<br>
  **CPUs:** 1<br>
  **Disk:** 20GB<br>
  **Provisioning:**<br>

* create unmanaged files in `/usr/local/`,`/etc/`
* modify configfile `/etc/crontab`
* change managed file `/usr/share/bash/helpfiles/read`
* remove managed file `/usr/share/bash/helpfiles/cd`
* unpack unmanaged-files.tgz in `/`


## machinery_leap

**Description**
  This VM is the inspecting system on which machinery is run.

  **Based on box:** machinery_opensuse_leap_kvm<br>
  **Vagrant provider used:** libvirt<br>
  **User credentials:**<br>
    *User:* root, *Password:* vagrant<br>
    *User:* vagrant, *Password:* vagrant<br>
  **Memory:** 1024M<br>
  **CPUs:** 1<br>
  **Disk:** 20GB<br>
  **Provisioning:**<br>

* build `machinery` rpm
* sync package and built folder into the VM
* install `machinery` rpms
