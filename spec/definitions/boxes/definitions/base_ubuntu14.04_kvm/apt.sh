# remove update repos
cat << EOF > /etc/apt/sources.list
deb http://de.archive.ubuntu.com/ubuntu/ trusty main restricted
deb-src http://de.archive.ubuntu.com/ubuntu/ trusty main restricted
EOF
apt-get -y update
apt-get -y install vim
apt-get -y install nfs-common
apt-get -y purge whiptail nano ppp pppconfig pppoeconf linux-image-extra-3.19.0-25-generic linux-headers-3.19.0-25-generic linux-headers-3.19.0-25
