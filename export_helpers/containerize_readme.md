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

Log out and in again to refresh the user's group.

## Set Up

When necessary, we've included a `setup.rb` script in your new containerized
application. This script uses the ruby client for the Docker Remote API so you
will need to install it as a gem.

    $ gem install docker-api

Once installed please make sure to run the setup script before running
`docker-compose up`.

    $ ./setup.rb

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

