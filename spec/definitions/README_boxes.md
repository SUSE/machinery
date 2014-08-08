# Documentation for veewee boxes

The veewee directory contains build definitions and installer configurations
for building veewee boxes that can be used by Vagrant to create VMs from
them.

When built, the boxes will be created in `./veewee` and can also be used from
outside the Vagrant environment.

By default the following two boxes are defined:

## base_opensuse13.1_kvm

**Used for:** Creating VM of inspected system.

  **OS:** openSUSE 13.1 (64bit)<br>
  **Disk size:** 20GB<br>
  **Memory:** 1024MB<br>
  **Credentials:**<br>
    *User:* root, *password:* vagrant<br>
    *User:* vagrant, *password:* vagrant, *public key:* https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub

### Postinstall modifications
* install ssh key for user vagrant
* remove `/var/log/YaST2/config_diff_*.log`
* remove `/etc/zypp/repos.d/dir-*.repo`
* remove `/etc/udev/rules.d/70-persistent-net.rules`
* remove `/etc/cron.daily/*`
* allow Vendorchange for package installation
* disallow installing recommended packages as dependencies
* allow vagrant to use sudo without password
* disable DNS lookups for ssh logins

## machinery_opensuse13.1_kvm

**Used for:** Creating VM of inspecting system.

  **OS:** openSUSE 13.1 (64bit)<br>
  **Disk size:** 20GB<br>
  **Memory:** 384MB<br>
  **Credentials:**<br>
    *User:* root, *password:* vagrant<br>
    *User:* vagrant, *password:* vagrant, *public key:* https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub

### Postinstall modifications:
* run package update
* install ssh key for user vagrant
* install packages needed for building gems
`gcc-c++ less make bison libtool ruby-devel vim`
* install packages needed for machinery:
`git libxslt1 libxslt-devel zlib-devel libxml2-devel libvirt-devel expect patch`
* install packages needed for building:
`kiwi kiwi-desc-vmxboot kiwi-tools db45-utils db-utils grub`
* allow vagrant to use sudo without password
* disable DNS lookups for ssh logins
* install gems:
`chef`, `puppet`
