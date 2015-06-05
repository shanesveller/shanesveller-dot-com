+++
comments = true
date = "2014-10-29T17:00:00-05:00"
layout = "post"
published = false
title = "Load-balancing Docker containers with Nginx and Consul-Template"

+++

> This article has been cross-posted here from my employer's [technical blog](http://tech.bellycard.com/).

We are investing a lot of research and development time into leveraging [Docker][docker] in the next generation of our internal infrastructure. One of the next components we need to build out to full maturity is being able to dynamically route web traffic from our [Nginx][nginx] load balancers to internal Docker containers in a performant way.

We are very passionate fans of the work of [HashiCorp][hashic] at Belly, and they recently published a new project named [Consul-Template][ctempl]. We were using an earlier HashiCorp tool named [consul-haproxy][chapro] to reconfigure our Nginx load-balancers based on Consul data. Consul-Template is a slightly more generalized tool that was fairly smooth to adopt.

[chapro]: https://github.com/hashicorp/consul-haproxy
[ctempl]: https://github.com/hashicorp/consul-template
[docker]: https://www.docker.com/
[hashic]: https://www.hashicorp.com
[kevin]: https://tech.bellycard.com/team/kevin-reedy

Let me walk you through a proof of concept I whipped up last week. Starting from an OSX computer with Homebrew and VirtualBox installed, we will be able to spin up a Docker-based environment that will load-balance HTTP traffic via Nginx to an arbitrary number of backend processes, all running in separate Docker containers.READMORE

## Architecture

At a high level, here is the construction of the current PoC. The following Docker containers are launched prior to the load-balancer being able to serve HTTP traffic correctly:

* [Consul][consul] for service discovery
* Nginx for load-balancing, plus Consul-Template
* [Registrator][regist] for registering backends into Consul&apos;s service catalog
* An arbitrary number of backend containers that can handle HTTP requests

The Nginx container listens on the public port 80, and runs Consul-Template. Consul-Template listens to Consul for changes to the service catalog, and will reconfigure and reload Nginx accordingly on new changes.

Registrator monitors Docker for new containers to be launched with exposed ports, and then registers a Consul Service accordingly. By setting environment variables within the containers, we can be more explicit about how the services should be registered with Consul. When a container quits or is removed, Registrator removes it from the service catalog automatically.

Finally, an example backend container is included for the load-balancer to proxy to. This could be replaced by any properly configured, locally-stateless HTTP-based app.

## Breakdown

Here is a list of the tools I have used below:

- [Boot2docker][b2d] 1.3.0
- [Consul][consul] 0.4.1
- [Consul-Template][ctempl] 0.1.0
- [Fig][fig] 1.0.0
- [Nginx][nginx] 1.7
- [Registrator][regist]

[b2d]: http://boot2docker.io/
[consul]: https://www.consul.io/
[fig]: http://www.fig.sh/
[nginx]: http://nginx.org/
[regist]: https://github.com/progrium/registrator

## Getting Started

Install `boot2docker` and `fig`:

```bash
brew update
brew install caskroom/cask/brew-cask fig
brew cask install boot2docker
```

Prepare `boot2docker` and fire it up:

```bash
boot2docker init
boot2docker upgrade
boot2docker up
docker version
docker ps
```

Tell the Docker CLI where to look for Docker, and tell Fig what to call the project:

```bash
export DOCKER_TLS_VERIFY=1
export DOCKER_HOST=tcp://192.168.59.103:2376
export DOCKER_CERT_PATH=$HOME/.boot2docker/certs/boot2docker-vm
export FIG_PROJECT_NAME=web
```

## Declaratively Configure A Multi-container Application

I have created a `fig.yml` file with several entries. If you are not familiar with the format, please read up [here][figyml] first. Essentially, this YAML file describes numerous Docker containers in detail, with instructions on what images or build instructions to use, how to launch them, what ports to expose and how they should be interconnected.

The command `fig` reads from this configuration file when determining what containers to launch and how, and is necessary because Docker currently doesn&apos;t have any native concepts of multi-container applications.

[figyml]: http://www.fig.sh/yml.html

```yaml
lb:
  build: ./
  links:
  - consul
  ports:
  - "80:80"
```

First up is the load balancer, which is based on Nginx and will dynamically proxy traffic to any number of backend containers. It listens on port `80` on the `boot2docker` host VM, and has a connection to talk directly to the Consul container below.

Notice that here I am using a `build` instruction rather than a pre-existing image from the Docker Registry. This is used to customize the container to launch `runit` as the container&apos;s first process rather than Nginx itself. Runit will then fire up Nginx and Consul-Template in parallel. Consul-Template is responsible for reconfiguring Nginx based on available backend containers.

```yaml
app:
  image: tutum/hello-world:latest
  environment:
    SERVICE_80_NAME: http
    SERVICE_NAME: app
    SERVICE_TAGS: production
  ports:
  - "80"
```

Next is the backend, based on the `hello-world` Docker image from [Tutum][tutum]. This image is based on Apache and renders a simple page displaying the server&apos;s hostname, which will vary per-container. It listens internally on port 80, which will be dynamically assigned to a high-numbered port on the host VM at runtime. We also set some environment variables here which will be used later by Registrator. This container would be replaced by your production application container.

[tutum]: https://www.tutum.co/

```yaml
consul:
  command: -server -bootstrap -advertise $ROUTABLE_IP
  image: progrium/consul:latest
  ports:
  - "8300:8300"
  - "8400:8400"
  - "8500:8500"
  - "8600:53/udp"
```

Consul, by [HashiCorp][hashic], provides a distributed key-value store and service discovery layer. Using the Registrator tool below, backend service containers are registered with Consul to say, &quot;Here I am, and these are the ports I listen on&quot;, etc. Several ports are exposed on the host VM to allow both local apps and entirely separate hosts to communicate with the Consul cluster - which in this example is just the one node. In this proof of concept, I was hard-coding a routable IP from `boot2docker`&apos;s `eth0` interface so that the containers all knew where to reach each other.

```yaml
registrator:
  command: consul://consul:8500
  image: progrium/registrator:latest
  links:
  - consul
  volumes:
  - "/var/run/docker.sock:/tmp/docker.sock"
```

Finally, here is some of the first glue that ties it all together. Registrator is a tool written by [Jeff Lindsay][progri] that watches for the starting and stopping of Docker containers, and will register Consul services for their published ports. You can provide environment variables, as we did above, to give it better hints about what to register. Since it talks to both Consul and the local Docker daemon, the appropriate link and volume are provided.

[progri]: http://twitter.com/progrium


## Configuring Nginx With Consul-Template

Through a Consul-Template template file, Nginx is configured to listen on port 80 and will answer to any hostname that resolves to the Docker host&apos;s IP address. All URIs will be proxied to one of the available backend containers based on which container has the fewest active connections.

You can observe the [template syntax][tmpstx] for Consul-Template to pull values from a Consul service in action below, which are based on Golang&apos;s templates from the standard library. The rest of the file is vanilla Nginx configuration syntax. Notice that we are specifically looking for the `app` service with the `production` tag, which were provided via environment variables in the App container&apos;s definition above. You could use the service and tag combination to correctly account for multiple data centers or multiple environments, for example.

[tmpstx]: https://github.com/hashicorp/consul-template#templating-language

```
upstream app {
  least_conn;
  {{range service "production.app"}}server {{.Address}}:{{.Port}} max_fails=3 fail_timeout=60 weight=1;
  {{else}}server 127.0.0.1:65535; # force a 502{{end}}
}

server {
  listen 80 default_server;

  location / {
    proxy_pass http://app;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

## See It In Action

This short, silent video demonstration was captured at 1280x720, so a full-screen or separate-tab viewing is recommended.

<iframe src="//player.vimeo.com/video/110409547" width="500" height="281" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

## Help Wanted

Even as a proof of concept, there is plenty of room for improvement here. We&apos;ve open sourced the current code [here](https://github.com/bellycard/docker-loadbalancer). Please feel free to play around with it!

Here are a few ideas where we might expand on this work, and would welcome any contributions or feedback:

* Alternatives to Fig for orchestrating the multi-container deployment
* Alternatives to Registrator for registering backend services to Consul
* Alternatives to Nginx for the HTTP load-balancing, such as HAProxy
* Routing to one of multiple backends based on requested hostname
* Variants that build from a different Docker base image than the [official Nginx image][ngximg]
* Examples of using more realistic backends
* Examples of running the described multi-container app on [CoreOS][coreos] via `fleet`

[coreos]: https://coreos.com/
[ngximg]: https://registry.hub.docker.com/_/nginx/
