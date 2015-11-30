+++
categories = ["Docker"]
date = "2015-08-31T10:15:00-05:00"
tags = ["docker","docker-machine","dotfiles","zsh"]
title = "Docker-Machine Lazy Loading"
+++

Like many, I use `docker-machine` (installed via
[Docker Toolbox](https://www.docker.com/docker-toolbox)) to develop Docker
images on OSX. I am terrible about remembering to launch the `docker-machine` VM
ahead of time, and I don't like having STDERR output or delays from launching
new shell tabs, so I wrote a quick lazy-load function inspired by
[Spacemacs](https://github.com/syl20bnr/spacemacs/).
<!--more-->
I use ZSH but this may work on Bash as well, and my VM is named `dev`. This will
intercept the first command that begins with `docker` during a given shell
session, and ensure that the VM has been booted and that the shell variables
`DOCKER_HOST` and `DOCKER_CERT_PATH` are set appropriately. It won't try to boot
the machine or update the shell environment until the first time a `docker`
command is attempted.

```zsh
docker() {
  unset -f docker
  # docker-machine create -d virtualbox dev
  # VBoxManage list runningvms | grep -E "^\"dev\"" >/dev/null 2>/dev/null || docker-machine start dev
  # docker-machine create -d vmwarefusion dev
  vmrun list | grep -E ".docker\/machine\/machines\/dev\/dev.vmx$" 2>&1 >/dev/null || docker-machine start dev
  eval "$(docker-machine env dev)"
  docker "$@"
}
```
