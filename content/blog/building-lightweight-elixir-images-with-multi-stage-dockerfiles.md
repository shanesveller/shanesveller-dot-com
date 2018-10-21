+++
title = "Building lightweight Elixir images with Multi-stage Dockerfiles"
author = ["Shane Sveller"]
date = 2018-10-19
lastmod = 2018-10-21T08:37:29-05:00
tags = ["docker", "elixir", "phoenix", "umbrella"]
categories = ["elixir"]
draft = true
+++

Back in August of this year, I [helped my friend Eric add a Docker image and
Docker Compose environment](https://github.com/oestrich/ex%5Fventure/pull/69) for his multiplayer game server, [ExVenture](https://exventure.org/). This
was primarily based on an iteration of [my own multi-stage Docker work](https://gist.github.com/shanesveller/d6e58ef40bbb1c11ca32ef0d62fda4a8) back
in February, which was for a Phoenix Umbrella app I'd been working on as a
side project at the time.

Let's pull back the curtain on my current active side project, which is also
a text-based multiplayer game server like Eric's, and talk through the
implications of and thought process behind each line of its Dockerfile.

```dockerfile
FROM elixir:1.7.3-alpine as builder

# The nuclear approach:
# RUN apk add --no-cache alpine-sdk
RUN apk add --no-cache \
    gcc \
    git \
    make \
    musl-dev

RUN mix local.rebar --force && \
    mix local.hex --force

FROM builder as releaser

WORKDIR /app
ENV MIX_ENV=prod
COPY mix.* /app/

# Explicit list of umbrella apps
RUN mkdir -p \
    /app/apps/chat \
    /app/apps/client \
    /app/apps/command_parser \
    /app/apps/game_world \
    /app/apps/gateway \
    /app/apps/metrics_exporter
COPY apps/chat/mix.* /app/apps/chat/
COPY apps/client/mix.* /app/apps/client/
COPY apps/command_parser/mix.* /app/apps/command_parser/
COPY apps/game_world/mix.* /app/apps/game_world/
COPY apps/gateway/mix.* /app/apps/gateway/
COPY apps/metrics_exporter/mix.* /app/apps/metrics_exporter/
RUN mix deps.get --only prod
RUN mix deps.compile

COPY . /app/
RUN mix release --env=prod --no-tar --name=ex_mud

FROM alpine:3.8 as runner
RUN apk add -U bash libssl1.0
WORKDIR /app
COPY --from=releaser /app/_build/prod/rel/ex_mud /app
EXPOSE 5556 5559
ENTRYPOINT ["/app/bin/ex_mud"]
CMD ["foreground"]
```

<!--more-->
