+++
title = "Kubernetes Native Phoenix Apps: Part 1"
author = ["Shane Sveller"]
date = 2018-10-28T14:15:00-05:00
lastmod = 2018-10-28T14:34:23-05:00
tags = ["docker", "elixir", "phoenix", "umbrella", "kubernetes"]
categories = ["elixir"]
draft = false
+++

As described in the introductory post, this article will briefly outline
the installation of Distillery 2 as well as including a deeper philosophical
and technical explanation of how I structure multi-stage Docker images for
Elixir/Phoenix applications.

<!--more-->

Published articles in this series:

-   [Introduction](/blog/2018/10/28/kubernetes-native-phoenix-apps-introduction/)
-   Part 1 (this post)


## Our Application {#our-application}

The [application](https://github.com/shanesveller/kube-native-phoenix) we're going to be working with throughout this series was
created as follows:

-   Phoenix 1.4 (RC2 at the time of writing)
-   Umbrella application
-   Using default components (Ecto, Postgres, Webpack)

Its actual content and functionality will intentionally be kept very
sparse, other than to demonstrate certain common scenarios, such as native
dependencies of well-known Hex packages.


## Installing Distillery 2 {#installing-distillery-2}

Generally speaking, we'll closely follow the existing Distillery 2
[installation guide](https://hexdocs.pm/distillery/introduction/installation.html). Paul and the other contributors have produced very
high-quality documentation as part of the 2.x release cycle. I'll call
specific attention to a few sections of these guides:

-   [Installation guide](https://hexdocs.pm/distillery/introduction/installation.html)
-   [Walkthrough](https://hexdocs.pm/distillery/introduction/walkthrough.html)
-   [Umbrella Projects](https://hexdocs.pm/distillery/introduction/umbrella%5Fprojects.html)
-   [Phoenix guide](https://hexdocs.pm/distillery/guides/phoenix%5Fwalkthrough.html)
-   [Deploying with Docker](https://hexdocs.pm/distillery/guides/working%5Fwith%5Fdocker.html)

The last guide is perhaps where we will diverge the most from the upstream
documentation. As I mentioned previously, this blog series will present an
opinionated and optimized experience, so we're going to make a few
different choices in how to structure our Docker image.

Before continuing, please make sure that you have completed the
installation of Distillery within your application, and that you can
successfully run `mix release` and get a working application.

For an example of what this looks like in our live application, please see
the git tree at commits `4b2e2cb..aa6c54e` [here](https://github.com/shanesveller/kube-native-phoenix/compare/4b2e2cb...aa6c54e).


## Creating our first Docker image {#creating-our-first-docker-image}

While there are many options and many opinions on how to construct an
optimal Docker image, here are my personal recommended priorities:

-   Strict compatibility with vanilla `docker build` commands on a recent
    version of the Docker daemon (~17.05+), which implies compatibility with
    a broad variety of CI/CD tools and environments
-   Smallest reasonable resulting image, achieved primarily through
    multi-stage builds and intentional choice of base images
-   High cache hit rate during iterative builds
-   No mixing of runtimes in build stages, i.e. no adding Node.js to an
    Elixir base image
-   Alpine Linux-based, with a pivot to the `-slim` images when absolutely
    necessary
-   Final image should have minimal system-level packages installed and rely
    on Distillery's ability to package the Erlang runtime system with a
    release


### Dockerfile {#dockerfile}

As mentioned, we're targeting `docker build` compatibility rather than one
of the other, possibly more sophisticated approaches.

Let's see the complete file first and then walk through it together in
small steps.

{{< highlight dockerfile "linenos=table, linenostart=1" >}}
# docker build -t kube_native:builder --target=builder .
FROM elixir:1.7.3-alpine as builder
RUN apk add --no-cache \
    gcc \
    git \
    make \
    musl-dev
RUN mix local.rebar --force && \
    mix local.hex --force
WORKDIR /app
ENV MIX_ENV=prod

# docker build -t kube_native:deps --target=deps .
FROM builder as deps
COPY mix.* /app/
# Explicit list of umbrella apps
RUN mkdir -p \
    /app/apps/kube_native \
    /app/apps/kube_native_web
COPY apps/kube_native/mix.* /app/apps/kube_native/
COPY apps/kube_native_web/mix.* /app/apps/kube_native_web/
RUN mix do deps.get --only prod, deps.compile

# docker build -t kube_native:frontend --target=frontend .
FROM node:10.12-alpine as frontend
WORKDIR /app
COPY apps/kube_native_web/assets/package*.json /app/
COPY --from=deps /app/deps/phoenix /deps/phoenix
COPY --from=deps /app/deps/phoenix_html /deps/phoenix_html
RUN npm ci
COPY apps/kube_native_web/assets /app
RUN npm run deploy

# docker build -t kube_native:releaser --target=releaser .
FROM deps as releaser
COPY . /app/
COPY --from=frontend /priv/static apps/kube_native_web/priv/static
RUN mix do phx.digest, release --env=prod --no-tar

# docker run -it --rm elixir:1.7.3-alpine sh -c 'head -n1 /etc/issue'
FROM alpine:3.8 as runner
RUN addgroup -g 1000 kube_native && \
    adduser -D -h /app \
      -G kube_native \
      -u 1000 \
      kube_native
RUN apk add -U bash libssl1.0
USER kube_native
WORKDIR /app
COPY --from=releaser /app/_build/prod/rel/kube_native_umbrella /app
EXPOSE 4000
ENTRYPOINT ["/app/bin/kube_native_umbrella"]
CMD ["foreground"]
{{< /highlight >}}

Code samples are described by their preceding text below.


#### Build environment {#build-environment}

First, we prepare a build stage named `builder` with the basic
prerequisites of an Elixir development environment, including some fairly
universally-required tooling for native extensions. This is where we'll
insert any additional development packages needed to compile certain Hex
dependencies in the future.

Note also that we don't get Hex or Rebar automatically installed with
this base image, and need to trigger those installations ourselves.

Finally, we'll be building our project inside the `/app` working
directory and defaulting to the `prod` Mix environment during Hex package
compilation. **This image is not intended for development purposes
whatsoever** and is fairly unsuitable for that use-case.

{{< highlight dockerfile "linenos=table, linenostart=2" >}}
FROM elixir:1.7.3-alpine as builder
RUN apk add --no-cache \
    gcc \
    git \
    make \
    musl-dev
RUN mix local.rebar --force && \
    mix local.hex --force
WORKDIR /app
ENV MIX_ENV=prod
{{< /highlight >}}

I'm using a specific tagged Elixir release here, targeting the `-alpine`
variant to build on top of Alpine Linux. The maintainers of this
"official" Docker image are not affiliated with Plataformatec or Erlang
Solutions, and one downside of this image stream is that they treat
certain tags as mutable.

At different calendar dates, the `1.7.3-alpine` image tag has included
differing versions of the underlying Erlang runtime. One way to hedge
against this would be to be more precise in our FROM line:

```dockerfile
FROM elixir:1.7.3-alpine@sha256:4eb30b05d0acc9e8821dde339f0e199ae616e0e9921fd84822c23fe6b1f81b6d
```

You can determine the digest to include by running `docker images
       --digests elixir`.

While it would be totally valid to install and compile both Erlang and
Elixir from source during this build phase, I do not consider this to be
at all necessary or a particularly valuable effort for most companies or
scenarios. Doing so requires you to absorb the maintenance burden of
"keeping up with the Joneses" and incorporating any necessary security
patches yourself, tracking the current release versions, and
understanding their own build-time dependencies.

If you find yourself with a requirement that cannot be satisfied under
Alpine Linux, or feel an anti-affinity for Alpine, or an affinity for
Debian, using a `-slim` base image variant will be largely identical to
this process. Start with replacing `apk` commands with their semantic
equivalent using `apt-get` (because `apt` makes no stability guarantees
about its input/output). You'll potentially have broader compatibility
with some corners of the software industry, at the cost of a slightly
larger runtime image.


#### Hex Dependencies {#hex-dependencies}

Next we acquire and compile all known Hex dependencies. This slightly
verbose layering structure allows us to get a very high cache hit rate
during Docker builds, because our dependencies are some of the slowest
and least-frequently changing portions of our application development
work.

Note here that for an umbrella application, we also need to descend into
each umbrella app and include its `mix.exs` content as well. In a
non-umbrella application, it's likely sufficient to only include the
highlighted lines.

Lines 17-21 are an unfortunate necessity for Umbrella applications, as
the `COPY` directive for Dockerfiles doesn't support multiple
destinations per the [documentation](https://docs.docker.com/engine/reference/builder/#copy), only multiple sources. As you add
more applications to your umbrella, new lines will need to be added here.
(I'm working on a Mix task library that will embody this and other
operational knowledge, which will be released to Hex in the coming
weeks.)

Now, this seems like an awful lot of ceremony, doesn't it? Here's the
payoff: without a technique that is similar to this in spirit,
application-level changes such as new behavior in a Phoenix controller or
new markup in a view template will **bust the Docker build cache** and
require all of the Hex dependencies to be downloaded and compiled anew.

This is a very common pattern across many programming languages when
creating Docker images, not just Elixir, so I'm satisfied with including
it here. You'll also see it again in the next section.

{{< highlight dockerfile "linenos=table, linenostart=13, hl_lines=1-3 10" >}}
# docker build -t kube_native:deps --target=deps .
FROM builder as deps
COPY mix.* /app/
# Explicit list of umbrella apps
RUN mkdir -p \
  /app/apps/kube_native \
  /app/apps/kube_native_web
COPY apps/kube_native/mix.* /app/apps/kube_native/
COPY apps/kube_native_web/mix.* /app/apps/kube_native_web/
RUN mix do deps.get --only prod, deps.compile
{{< /highlight >}}


#### NPM/Asset Dependencies {#npm-asset-dependencies}

Similar to how we constructed the `deps` phase just above, we're pulling
in a language-specific but otherwise unadorned base image to do the heavy
lifting, as I don't wish to maintain or even be particularly
familiar with packing Node when it's not a **runtime** dependency.

We grab the **package.json** and **package-lock.json** files from our project
to describe our JavaScript-ecosystem dependencies, and also bundle in the
Javascript assets that are included with our previously-acquired Hex
packages. Following that, we use the somewhat-recent `npm ci` command,
which is optimal for the scenario where we're not looking to upgrade or
otherwise change our JS dependencies, merely reproduce them as-is.

After the NPM dependency tree is resolved, we pull in the rest of our
locally-authored frontend content and then use an NPM task to run a
production-friendly Webpack build of our assets.

{{< highlight dockerfile "linenos=table, linenostart=24" >}}
# docker build -t kube_native:frontend --target=frontend .
FROM node:10.12-alpine as frontend
WORKDIR /app
COPY apps/kube_native_web/assets/package*.json /app/
COPY --from=deps /app/deps/phoenix /deps/phoenix
COPY --from=deps /app/deps/phoenix_html /deps/phoenix_html
RUN npm ci
COPY apps/kube_native_web/assets /app
RUN npm run deploy
{{< /highlight >}}


#### Compile release {#compile-release}

Now it's time to tie all of this together into a Distillery release! We
pull in our Elixir dependencies from the previous phase as our new base
image, and then include only the compiled assets from the Node stage in
our `/priv/static` directory. `mix phx.digest` takes those in and
fingerprints them, and then finally we run `mix release` to build our
package without ~tar~ring it up, as we'd just have to unpack again in the
next and final stage.

{{< highlight dockerfile "linenos=table, linenostart=34" >}}
# docker build -t kube_native:releaser --target=releaser .
FROM deps as releaser
COPY . /app/
COPY --from=frontend /priv/static apps/kube_native_web/priv/static
RUN mix do phx.digest, release --env=prod --no-tar
{{< /highlight >}}


#### Build runtime image {#build-runtime-image}

Here's how we achieve our minimal runtime image sizes. At the time of
writing, the previous stage produces a Docker image weighing at about
240MB, and with 20 separate image layers. For our final image, we start
over from a compatible release of Alpine Linux. It's a strong
recommendation that whenever possible, we not run containerized processes
as the root user within the image, so we create a static group and user
for this application, each with ID `1000`, and switch to that user. The
particular number likely will not matter up until the point that you need
to reconcile file ownership across Docker volumes or between host and
container.

We pull in the uncompressed release built in the previous stage, expose
the default Phoenix port, and set our `ENTRYPOINT` to launch the script
provided by Distillery. The `CMD` directive tells the image that by
default it should launch the application in the foreground without
interactivity.

We'll see later in the series that this opens up the opportunity to run
custom commands more easily within our image, specified at runtime,
without altering the image.

{{< highlight dockerfile "linenos=table, linenostart=40" >}}
# docker run -it --rm elixir:1.7.3-alpine sh -c 'head -n1 /etc/issue'
FROM alpine:3.8 as runner
RUN addgroup -g 1000 kube_native && \
    adduser -D -h /app \
      -G kube_native \
      -u 1000 \
      kube_native
RUN apk add -U bash libssl1.0
USER kube_native
WORKDIR /app
COPY --from=releaser /app/_build/prod/rel/kube_native_umbrella /app
EXPOSE 4000
ENTRYPOINT ["/app/bin/kube_native_umbrella"]
CMD ["foreground"]
{{< /highlight >}}


### Dockerignore {#dockerignore}

We'll continue the process of Dockerizing this Phoenix application with an
oft-forgotten step: the `.dockerignore` file. This file will feel similar to
the syntax of a `.gitignore` file, but does not intentionally mimic its
structure [as documented by Docker](https://docs.docker.com/engine/reference/builder/#dockerignore-file).

We can start ourselves on good footing by copying the existing `.gitignore`
provided by the `phx.new` task when we started our project:

```shell
echo '# Default gitignore content' > .dockerignore
cat .gitignore >> .dockerignore
```

And next we'll customize it for our needs by adding the following content:

{{< highlight gitignore "linenos=table, linenostart=1, hl_lines=2 6 8 11-14" >}}
# Developer tools
.git
.tool-versions

# Umbrella structure
apps/**/config/*.secret.exs
apps/**/node_modules
apps/**/priv/cert
apps/**/priv/static

# Docker
.dockerignore
Dockerfile
docker-compose.yml
{{< /highlight >}}

The value in a well-formed `.dockerignore` file is two-fold in my eyes. It
prevents local content that shouldn't be persisted from appearing in Docker
images that were built locally, such as secrets, tooling/editor artifacts,
or compiled content like our static assets. (We're just going to recompile
those in a build stage, anyway!) It also minimizes the local changes that
will contribute to a cache miss when building updated versions of an
existing Docker image.

The logic here is fairly subjective, but I feel that the following tasks
should not _inherently_ cause a fresh image build:

-   Git commits persisting your changes, without other filesystem changes
    (line 2)
-   Non-semantic changes to how we define the Dockerfile, such as whitespace
    or comments (lines 12-13)
    -   Docker will automatically cache-bust for us if the changes are meaningful
-   Changes to a Docker Compose environment definition (line 14)
-   Changes to development-only or gitignored secrets files (lines 6, 8)


### Caveats {#caveats}

This approach comes with a lot of benefits, but it was at least one
significant drawback - "cold" builds, that don't have applicable caches
present, are just as slow as a single-stage linear approach. Thankfully,
this can be mitigated via workflow changes.

If you build your images with this command or similar, you'll notice that
you also get some "dangling" images on your Docker host:

```shell
docker build -t kube_native:$git_sha .
```

These images are ephemeral outputs of the stages of our build, and can be
intentionally captured as a differently-tagged image. One thing this
avoids, other than ambiguity in `docker images` command output, is that
these images would then no longer be cleared by mechanisms like `docker
      system prune`, without the `-a` flag.

These preliminary stage images could even be pushed to the same Docker
image registry that your runtime image goes to, so that multiple
developers can share the existing cached work without repeating it until
necessary.

There were comments throughout the above Dockerfile section, but here's
the alternate workflow I'm proposing:

```shell
docker build -t kube_native:builder --target=builder .
docker build -t kube_native:deps --target=deps .
docker build -t kube_native:frontend --target=frontend .
docker build -t kube_native:releaser --target=releaser .
docker build -t kube_native:$git_sha .
docker tag kube_native:builder my.registry.com/kube_native:builder
docker push my.registry.com/kube_native:builder
docker tag kube_native:deps my.registry.com/kube_native:deps
docker push my.registry.com/kube_native:deps
# ...
docker push my.registry.com/kube_native:$git_sha
```

This is verbose, but precise, and ripe for automation via Makefile, Mix
tasks, etc. You can also introduce a growing list of `--cache-from` flags
to the above commands to specify what images are considered "upstream" of
a given target.

Other developers, and your CI/CD systems, can first `docker pull` the
above tagged images to speed up their local builds. Anecdotally, I saw
Google Cloud Builder save around 2/3 of my build time by following this
technique.


## Code Checkpoint {#code-checkpoint}

The work presented in this post is reflected in git commit d239377
available [here](https://github.com/shanesveller/kube-native-phoenix/tree/d239377bfbc910c455b2498d2e3bdfbe6642e857). You can compare these changes to the initial commit [here](https://github.com/shanesveller/kube-native-phoenix/compare/4b2e2cb...d239377).


## Appendix {#appendix}


### Software/Tool Versions {#software-tool-versions}

| Software   | Version    |
|------------|------------|
| Distillery | 2.0.10     |
| Docker     | 18.06.1-ce |
| Elixir     | 1.7.3      |
| Erlang     | 21.1.1     |
| Phoenix    | 1.4-rc.2   |


### Identifying Alpine base release {#identifying-alpine-base-release}

```shell
docker run -it --rm elixir:1.7.3-alpine sh -c 'head -n1 /etc/issue'
```
