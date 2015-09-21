FROM opensuse:13.2

RUN zypper -n --gpg-auto-import-keys ar http://download.opensuse.org/repositories/Virtualization:/containers/openSUSE_13.2/ virt
RUN zypper -n --gpg-auto-import-keys refresh
RUN zypper -n --gpg-auto-import-keys update
RUN zypper -n --gpg-auto-import-keys install docker-distribution-registry

ADD ./data/etc/registry /etc/registry

EXPOSE 5000
ENTRYPOINT ["registry"]
CMD ["/etc/registry/config.yml"]
