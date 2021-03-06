+++
date = "2014-02-04T10:47:09-05:00"
draft = true
title = "Using Docker transparently on OSX"

+++

[Docker](http://www.docker.io) current requires a Linux OS to run due to using
kernel technologies that are specific to this platform, such as `lxc`.

You can use Docker fairly painlessly on an OSX development machine by leveraging
vagrant and some work by Mitchell Hashimoto and Steeve Morin.
<!--more-->
# Installing prerequisites

These commands require `homebrew`.

## Virtualbox + Vagrant
``` shell
$ brew tap phinze/cask
$ brew install brew-cask
$ brew cask install virtualbox vagrant
```

## Docker
``` shell
$ brew tap homebrew/binary
$ brew install docker
```

# Vagrantfile

Create a directory to store your dockerfiles, and save the following file as
your `Vagrantfile` in that location. You may want to adjust the
[forwarded ports](http://docs.vagrantup.com/v2/networking/forwarded_ports.html)
as necessary depending on what services you're developing, or add a
[private IP address](http://docs.vagrantup.com/v2/networking/private_network.html)
for convenient external access, etc. Please see the
[Vagrant docs](http://docs.vagrantup.com/v2/) for more information.

```ruby
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "boot2docker-0.5.4"

  config.vm.box_url = "https://github.com/mitchellh/boot2docker-vagrant-box/releases/download/v0.5.4/boot2docker_virtualbox.box"

  config.vm.network :forwarded_port, guest: 80, host: 8080
end
```

# Usage

``` shell
$ cd <path to Vagrantfile> && vagrant up
$ export DOCKER_HOST=localhost
$ docker version
$ docker pull ubuntu:12.04
$ docker run -i -t ubuntu /bin/bash
$ docker build -t <tag> <OSX-local path to folder with Dockerfile>
$ docker run -i -t <tag> [<command>]
```

# Gotchas

Mounting local folders as a volume on a running instance of an image currently
doesn't work on this method. You'd have to put the files on the VM running
Docker, and then SSH into it and use `docker run` from there.

The (incredibly lightweight) `boot2docker` VM used in this example does not
currently support Vagrant/Virtualbox shared folders easily if at all, so
if you need to do so, you may want to move to a full-blown Linux instance that
Docker supports, such as Ubuntu.

# Example repo

I've been playing with writing
[my own Dockerfiles](https://github.com/shanesveller/dockerfiles) and have used
the above technique in the git repo.

