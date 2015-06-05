+++
date = "2015-06-11T13:00:00-05:00"
title = "Running a Phoenix app via Docker-Compose"

+++

It's possible to run Chris McCord's [sample Phoenix chat app][chat_app] in a [Docker][docker] environment easily using
[`docker-compose`][docker_compose].
<!--more-->
# Concept

When complete, this project will launch an instance of the chat app, along with a Postgres database, in a Docker-based
environment using `docker-compose`. `docker-compose` allows users to declaratively configure an app that requires multiple
Docker containers running and linked together to function. Once configured via a YAML file, it's possible to start,
stop, restart, etc. the app in part or whole via a [straightforward CLI][docker_compose_cli].

One quick disclaimer:

> **This article outlines a proof-of-concept and should not be followed to the letter for production deployments.**

Expect possible future content from me about deployment methods that are more appropriate for production use.

Lastly, this article has little to no beginner-friendly material about Docker itself. There is lots of material on this
subject already available, but if you have trouble finding some, please let me know and I'll help you look!

[chat_app]: https://github.com/chrismccord/phoenix_chat_example
[docker]: https://www.docker.com/whatisdocker/
[docker_compose]: https://docs.docker.com/compose/ 
[docker_compose_cli]: https://docs.docker.com/compose/cli/

# Prerequisites

If you want to follow along, you'll need the following tools installed and configured, which you can do by following
[the directions in my previous post][previous_post]. I've noted the specific versions of each tool I used.

* Docker-Compose (aka Fig) (`1.2.0`)
* boot2docker (if running on OSX) (`1.5.0`)
* Docker (if running on Linux) (`1.5.0`)

You'll also need to check out ~~a copy of~~ my fork of Chris' example app:

```shell
git clone -b docker-compose https://github.com/shanesveller/phoenix_chat_example.git
```

All files and commands described below should be run from or created within this directory.

# Preparing the App

I've detailed the changes I've made to the original chat app for the purposes of this project in the
[appendix][required_changes] below. Perhaps the most interesting and necessary is allowing the app to locate its
database via an environment variable, by making a change to the [`config/prod.secret.exs`][config_prod_secret] file:

```diff
diff --git a/config/prod.secret.exs b/config/prod.secret.exs
index f9cdc8f..e3963bc 100644
--- a/config/prod.secret.exs
+++ b/config/prod.secret.exs
@@ -9,6 +9,4 @@ config :chat, Chat.Endpoint,
 # Configure your database
 config :chat, Chat.Repo,
   adapter: Ecto.Adapters.Postgres,
-  username: "postgres",
-  password: "postgres",
-  database: "chat_prod"
+  url: {:system, "DATABASE_URL"}
```

[config_prod_secret]: {{< relref "#config-prod-secret-exs" >}}
[previous_post]: {{< relref "2014-10-29-load-balancing-docker-containers-with-nginx-and-consul-template.md#getting-started" >}}
[required_changes]: {{< relref "#required-app-changes" >}}

# Configuring Docker-Compose

To instruct `docker-compose` on how to launch one or more containers, I've created a `docker-compose.yml` file in the
root of the project. In this file, I've declared two types of Docker containers: the app itself (`web`) and a supporting
Postgres database (`db`). The YAML file configures the database's default superuser, and links the app container to the
database while configuring it with the correct credentials, and finally exposes port 4001 to external traffic. The `db`
container uses [an official Docker image][pg_image] for Postgres 9.4, and the `web` container is built from the local
repository via a [`Dockerfile`][app_dockerfile].

*While the example chat app doesn't actually seem to make much if any use of Ecto, I'm going to proceed as if a valid
 database were a hard requirement, as it will be in most Phoenix apps.*

```yaml
# docker-compose.yml
web:
  build: .
  environment:
    DATABASE_URL: ecto://chat:chat@db/chat_prod
    PORT: 4001
  links:
    - db
  ports:
    - 4001:4001
db:
  image: postgres:9.4
  environment:
    POSTGRES_USER: chat
    POSTGRES_PASSWORD: chat
```

[app_dockerfile]: {{< relref "#app-dockerfile" >}}
[pg_image]: https://registry.hub.docker.com/_/postgres/

# App Dockerfile

In [my fork of the chat app][chat_fork], I've created a Dockerfile that uses
[my Phoenix-ready image][phoenix_image_source] as a base. This base image is available as an
[automated build on Docker Hub][phoenix_image]. The image's source is publicly available and is explained in more detail
in the [appendix]({{< ref "#elixir-docker-image" >}}) below. The image uses some [`ONBUILD`][onbuild] instructions to
automate certain steps when it used as a base image, which automate a few of the more tedious common steps.

[chat_fork]: https://github.com/shanesveller/phoenix_chat_example/tree/docker-compose
[onbuild]: http://docs.docker.com/reference/builder/#onbuild
[phoenix_image]: https://registry.hub.docker.com/u/shanesveller/phoenix-framework/
[phoenix_image_source]: https://github.com/shanesveller/docker-elixir-lang

```
# Dockerfile
FROM shanesveller/phoenix:latest

COPY . /usr/src/app
RUN node_modules/brunch/bin/brunch build --production
RUN mix do compile

ENV PORT 4001
EXPOSE 4001
CMD ["mix","phoenix.server"]
```

In the Dockerfile, after the `ONBUILD` commands from the base image are run, the following occurs:

* All application code is added to the Docker image
* Brunch is used to compile any frontend static assets, with `production` optimizations enabled
* All application-specific Elixir code is compiled, also with `production` optimizations
* Port `4001` is configured to be exposed to the outside world when the Docker image is run
* A default command is provided using [`exec`-style array notation][docker_cmd_exec] for the command and arguments

The default command is what will execute inside the container if a user runs `docker run $app_image` or `docker-compose
run web` without including an explicit command to run.

Currently, the resulting image is about 322MB in size, and contains everything needed to run the app except its
database. The other public images I've seen available for the Elixir language were much larger - one base image is
already some 715MB in size without any of your own app code or dependencies included.

[docker_cmd_exec]: http://docs.docker.com/reference/builder/#cmd

# Building the App

```shell
docker-compose pull
docker-compose build
```

The first command will pull down any base images that are not custom builds - in this case, just the `postgres` image
for the `db` container. The second command will then build an image for the chat app based on its Dockerfile and local
folders/files.

# Launching the App

Once the app has been configured for `docker-compose` and the required images have been pulled down or built, I can
launch the app and its database by executing:

```shell
docker-compose up
```

The first time this is executed, this will launch the app itself, and an empty Postgres instance.

> If running this app on OSX via `boot2docker`, it's worth noting that the `EXPOSE`d port is mapped on the `boot2docker`
> virtual machine, not on your host machine. The running app is therefore not reachable from outside your own computer
> without taking special efforts, which are not covered here.

## Provisioning the Database

In order to create the database within the running Postgres instance, execute this command:

```shell
docker-compose run --rm app sh -c "mix ecto.create"
```

*This command behaved unpredictably and sometimes failed without useful output until I added the `sh -c` wrapping the
 `mix` command*.

## Running Ecto Migrations

When necessary, Ecto migrations can be run against the existing database by executing the command:

```shell
docker-compose run --rm app sh -c "mix ecto.migrate"
```

## Connecting to the App

After launching the app and possibly running `ecto` migrations, you can use your web browser to connect to the Docker
host at port `4001` and you should be able to access the chat app. On a Linux host, this will typically be `localhost`.
On an OSX host via `boot2docker`, you can easily get the IP of the VM via `, which will
automatically place the IP address into your clipboard for easy pasting into your browser.

```shell
boot2docker ip | pbpaste
```

Again, this will typically either be `http://localhost:4001/` or `http://192.168.59.103:4001/`.


# Caveats and Trade-Offs

There are some tradeoffs and downsides to the approach outlined above, including but not limited to:

This method is not production-ready for several reasons, but one of the most important ones is that the database
container is ephemeral in nature and maybe be destroyed and recreated numerous times during the `docker-compose`
workflow, which will destroy all content.

No consideration has been made for HTTP load balancing or any other form of redundancy, so if the running `web` container
quits, no further HTTP traffic will succeed without intervention to restart the container.

Database data has not been configured to be backed up or even persisted outside of the Docker container it runs in.

Perhaps this goes without saying, but you'll need to have Docker available or installable on your deployment target OS.
This currently rules out nearly anything but Linux as a target.

Using Docker images for deployment of apps makes it difficult, but not necessarily impossible, to perform "live" or
"hot" code replacement made possible by the Erlang VM.

The ports required for IEx remote shells, `:observer`, etc. are not exposed outside the container, so remote
introspection is also difficult without modifications or usage of `docker exec` to attach to the running container.

# Further Reading

If this article interests you, you may like [my previous post][previous_post] regarding service discovery and load
balancing of Docker containers via Consul and Nginx. I'd also recommend viewing the documentation for the tools I've
discussed:

* [Boot2Docker][boot2docker]
* [Docker][docker]
* [Docker-Compose][docker_compose]

[boot2docker]: https://github.com/boot2docker/boot2docker-cli#usage

# Credits

Thanks, most of all, to **Jose Valim** for creating Elixir, and **Chris McCord** for creating Phoenix Framework. Thank you also
to the early reader Collin Miller for his feedback.

# Feedback

Got questions or concerns? Did I miss something, make a mistake, or leave something unclear? Please leave a comment
below, or reach out to me on [Twitter][twitter] or the [Elixir slack team][slack]! I'm `@shanesveller` in both cases.

[slack]: http://elixir-slackin.herokuapp.com/
[twitter]: http://twitter.com/shanesveller

# Appendix

## Elixir Docker image

My [Elixir base image][elixir_image_source] starts from Debian Wheezy and installs Erlang and Elixir via APT
repositories, expanding slightly on the [official Linux install instructions][elixir_install]. The image is available on
Docker Hub as an [automated build][elixir_image] or can be built from source. I have endeavored to follow current
[best practices][docker_best_practices] to keep the image small. Currently this base image weighs in at around 150MB.

```
# Dockerfile
FROM debian:7

MAINTAINER Shane Sveller <shane@shanesveller.com>

ADD locale.gen /etc/locale.gen
RUN apt-get update -qq && \
    apt-get -y install locales && \
    apt-get clean -y && \
    rm -rf /var/cache/apt/* && \
    locale-gen
ENV LANG en_US.UTF-8

RUN apt-get update -q && \
    apt-get -y install curl && \
    curl -o /tmp/erlang.deb http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
    DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/erlang.deb && \
    rm -rf /tmp/erlang.deb && \
    apt-get update -q && \
    apt-get install -y elixir && \
    apt-get clean -y && \
    rm -rf /var/cache/apt/*

RUN mix local.hex --force && \
    mix local.rebar --force
```

Here's the current Dockerfile for my [Elixir Docker image][elixir_image]. Let's break this down. The first grouping of
ADD, RUN, ENV provides a default OS-level locale setting that mitigate a warning from the Elixir runtime related to
UTF-8 support.

The next long RUN command enables the Erlang Solutions APT repository, then installs the latest available Elixir from the
repository, and cleans up after itself as much as possible. This is all done in a single Docker image layer, to prevent
temporary files from making their way into the finale image.

Finally, Hex and Rebar are installed to make later usage of `mix deps` subcommands as smooth as possible.

[docker_best_practices]: https://docs.docker.com/articles/dockerfile_best-practices/
[elixir_image]: https://registry.hub.docker.com/u/shanesveller/elixir-lang/
[elixir_image_source]: https://github.com/shanesveller/docker-elixir-lang
[elixir_install]: http://elixir-lang.org/install.html#unix-%28and-unix-like%29

## Phoenix Docker Image

```
# Dockerfile
FROM shanesveller/elixir-lang:latest

MAINTAINER Shane Sveller <shane@shanesveller.com>

RUN apt-get update -q && \
    apt-get -y install apt-transport-https && \
    curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo 'deb https://deb.nodesource.com/node_0.12 wheezy main' > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update -q && \
    apt-get -y install git locales nodejs && \
    apt-get clean -y && \
    rm -rf /var/cache/apt/*

ONBUILD WORKDIR /usr/src/app

ONBUILD COPY *.js* /usr/src/app/
ONBUILD RUN npm install

ONBUILD ENV MIX_ENV prod
ONBUILD COPY mix.* /usr/src/app/
ONBUILD COPY config /usr/src/app/
ONBUILD RUN mix do deps.get, deps.compile
```

My [Phoenix-ready Docker image][phoenix_image] has some additional steps added for user convenience. Node.js is
installed via [NodeSource][nodesource]'s APT repository, and the installation of `npm` and `mix` dependencies has been
automated.

Node.js, npm, and npm dependencies are included to enable the [Brunch-based asset pipeline][brunch_assets] available in
recent Phoenix apps. Since the files like `brunch-config.js` and `packages.json` are unlikely to change often,
installing these early reduces the work needed on subsequent builds thanks to Docker's layer caching.

The `MIX_ENV` environment variable is set to `prod`, to compile all Elixir code with production-ready optimizations
in place.

Finally, this Dockerfile adds **just** the Elixir files necessary to install all of the Mix dependencies, and then perform the
installation and compilation of just those dependencies. Again, these will hopefully change far less frequently than
your regular application code, so we get some Docker caching speed-up on later builds.

Currently, this image weighs in at around 241 MB.

[brunch_assets]: http://www.phoenixframework.org/v0.13.1/blog/phoenix-0100-released-with-assets-handling-generat#static-asset-handling
[nodesource]: https://nodesource.com/blog/nodejs-v012-iojs-and-the-nodesource-linux-repositoriek

## Required App Changes

### .dockerignore

This will help keep the resulting Docker image svelte by excluding various artifacts of the development process, and
also will cause all dependencies (both Elixir and front-end) to be freshly downloaded and compiled at build-time, rather
than use the compilation artifacts from the developer's machine.

```
# .dockerignore
.git
Dockerfile

# Mix artifacts
_build
deps
*.ez

# Generate on crash by the VM
erl_crash.dump

# Static artifacts
node_modules
```

### Dockerfile

This will build a docker image for the Elixir app from an image based on my [Phoenix-ready docker image]({{< relref
"#elixir-docker-image">}} ).

```
# Dockerfile
FROM shanesveller/phoenix-framework:latest

COPY . /usr/src/app
RUN node_modules/brunch/bin/brunch build --production
RUN mix do compile, compile.protocols

ENV PORT 4001
EXPOSE 4001
CMD ["mix","phoenix.server"]
```

### Mix.exs

Making these changes will cause Elixir 1.0.4 or later to automatically compile protocols and perform other optimizations
when `MIX_ENV` is `prod`. See the [announcement blog post][elixir_104] on the Plataformatec blog for more details.

```diff
diff --git a/mix.exs b/mix.exs
index 17da92f..fea912e 100644
--- a/mix.exs
+++ b/mix.exs
@@ -7,6 +7,8 @@ defmodule Chat.Mixfile do
      elixir: "~> 1.0",
      elixirc_paths: ["lib", "web"],
      compilers: [:phoenix] ++ Mix.compilers,
+     build_embedded: Mix.env == :prod,
+     start_permanent: Mix.env == :prod,
      deps: deps]
   end
```

[elixir_104]: http://blog.plataformatec.com.br/2015/04/build-embedded-and-start-permanent-in-elixir-1-0-4/

### config/prod.secret.exs

Making this change allows the app to locate its database via a runtime environment variable, similar to the
recommendations of [The Twelve Factor App](http://12factor.net/). *This diff is identical to the one displayed above in
the [Preparing the App][preparing] section.*

```diff
diff --git a/config/prod.secret.exs b/config/prod.secret.exs
index f9cdc8f..e3963bc 100644
--- a/config/prod.secret.exs
+++ b/config/prod.secret.exs
@@ -9,6 +9,4 @@ config :chat, Chat.Endpoint,
 # Configure your database
 config :chat, Chat.Repo,
   adapter: Ecto.Adapters.Postgres,
-  username: "postgres",
-  password: "postgres",
-  database: "chat_prod"
+  url: {:system, "DATABASE_URL"}
```

[preparing]: {{< relref "preparing-the-app" >}}
