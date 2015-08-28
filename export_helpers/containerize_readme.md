# README for Docker Containers created by Machinery

This directory contains a (Docker Compose) Container configuration that was exported by
Machinery.

The user is expected to be familiar with using Docker.
Details on Docker can be found at https://www.docker.com/.

## Requirements

Docker and docker-compose are required. Packages are available in the Virtualization repository.

Install on openSUSE 13.2:

    sudo zypper ar -f http://download.opensuse.org/repositories/Virtualization:/containers/openSUSE_13.2/ virt
    sudo zypper refresh
    sudo zypper in docker docker-compose
    sudo usermod -aG docker $(whoami)
    sudo systemctl start docker

## Managing Docker containers

Run container:

    docker-compose up

Run container as daemon in background:

    docker-compose up -d

Shows list of all running containers:

    docker-compose ps

Stop the container:

    docker-compose kill

Remove the container image:

    docker-compose rm -vf

