+++
title = "Kubernetes Native Phoenix Apps: Part 2"
author = ["Shane Sveller"]
date = 2018-11-13T09:00:00-06:00
lastmod = 2018-12-04T09:36:45-06:00
tags = ["docker", "docker-compose", "elixir", "phoenix", "umbrella", "kubernetes"]
categories = ["elixir"]
draft = false
+++

One of the quickest ways to rapidly prototype and confirm that your new
Docker image is viable is to stand it up in a Docker-Compose environment. I
often skip this step nowadays but it's still a very useful validation step,
and is more generally applicable in open source projects where we can't
fully assume Kubernetes as a target.

<!--more-->

That said, **Docker Compose is in no way an appropriate mechanism for
production-grade deployments** serving paying customers. This phase of the
series is provided purely for educational purposes.

Some of these principles and some of the required Elixir code changes will
carry forward directly into the Kubernetes-based model later in the series -
particularly around how we configure our database connection and perform
seeds/migrations.

Published articles in this series:

-   [Introduction](/blog/2018/10/28/kubernetes-native-phoenix-apps-introduction/)
-   [Part 1](/blog/2018/10/28/kubernetes-native-phoenix-apps-part-1/)
-   Part 2 (this post)
-   [Part 3](/blog/2018/11/16/kubernetes-native-phoenix-apps-part-3/)


## Runtime Configuration {#runtime-configuration}

In order to make our application slightly more viable in different
deployment environments, we're going to borrow a page from the [Twelve
Factor Apps](https://12factor.net/) model, starting with the configuration for our database
connection.


### Ecto Database Connection {#ecto-database-connection}

For this first pass, we'll follow [Ecto's documentation](https://hexdocs.pm/ecto/3.0.1/Ecto.Repo.html#module-urls) to enable
runtime-configured `DATABASE_URL` during an `init/2` callback on our `Repo`:

{{< highlight elixir "linenos=table, linenostart=1, hl_lines=6-8" >}}
defmodule KubeNative.Repo do
  use Ecto.Repo,
    otp_app: :kube_native,
    adapter: Ecto.Adapters.Postgres

  def init(_type, config) do
    {:ok, Keyword.put(config, :url, System.get_env("DATABASE_URL"))}
  end
end
{{< /highlight >}}

Unfortunately, not every piece of our project can be configured as
gracefully using similar techniques. This especially includes external
libraries - which is something Ecto core team member Michał Muskała has
[written passionately and intelligently about](https://michal.muskala.eu/2017/07/30/configuring-elixir-libraries.html) in the not-too-distant past.
I'm still hoping to see some conventions on this subject emerge from the
community at large, but we are much closer to having adequate tooling on
this topic today than we were in 2017 when Michał's post was written.


### Other Configuration and Secrets {#other-configuration-and-secrets}

Here's one of the first instances where I'm going to genuinely cut some
corners and gloss over a little bit, because there's not as much
educational value in the Docker-Compose way of doing this. Some of it won't
survive intact into the Kubernetes-based implementation. Additionally,
since we're directly targeting Kubernetes in a later blog post, I will be
bypassing Docker's support for secrets management as part of their Swarm
offering.

Prior to the advent of Distillery 2, it was much harder for the community
to grok the available means to provide "late-binding" runtime-specific
information that isn't, shouldn't be, and perhaps **can't** be available at
build-time. This distinction between build-time and run-time configuration
challenged newcomers and even experienced Elixir developers. That
situation is much improved with the introduction of Distillery's
[Configuration Providers](https://hexdocs.pm/distillery/config/runtime.html#config-providers), which provide an extensible hook for sourcing
runtime information as the application starts up.

This next snippet uses the built-in [Mix Configuration Provider](https://hexdocs.pm/distillery/config/runtime.html#mix-config-provider) to keep us
in familiar territory for now. What the configuration instructs Distillery
to do is to include an in-repository file named `rel/config/config.exs`
into the release at the relative path `etc/config.exs`, and to consume
that content via the Mix configuration provider at boot-time.

Notably, **this file's contents can be extended or replaced** _after_ the
release is built, giving us a means to introduce certain configuration
details as late as possible, just before the BEAM runtime starts.

If you read the documentation about configuration providers, you'll learn
that most of the various commands are actually starting a separate BEAM
process first that **does** have access to `Mix`, calculating the derived
information, and writing it out to disk for the release to consume when it
starts "for real" moments later.

```elixir
# rel/config.exs
environment :prod do
  set config_providers: [
    {Mix.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]}
  ]
  set overlays: [
    {:copy, "rel/config/config.exs", "etc/config.exs"}
  ]
end
```

The content of the file is, for now, based once again on Distillery's
documentation, which highlights a few Phoenix-isms that are desirable
examples for runtime configuration.

```elixir
# rel/config/config.exs
use Mix.Config

port = String.to_integer(System.get_env("PORT") || "4000")

config :kube_native_web, KubeNativeWeb.Endpoint,
  http: [port: port],
  url: [host: System.get_env("HOSTNAME"), port: port],
  secret_key_base: System.get_env("SECRET_KEY_BASE")
```

Later in the series, we'll introduce actual data here.


## Docker Compose Environment Definition {#docker-compose-environment-definition}

> Our [application](https://github.com/shanesveller/kube-native-phoenix) relies on PostgreSQL 10, so we'll want to account for that
> in the `docker-compose.yml` we create.

This Docker-Compose environment is going to be extremely simple and
minimal, and as I mentioned at the beginning of the post, **is not
production ready**. Please don't use it for anything more than a learning
exercise or validating step on your way to Kubernetes.

Code samples are described by their preceding text below.

Full sample:

{{< highlight yaml "linenos=table, linenostart=1" >}}
# https://docs.docker.com/compose/compose-file/
version: '3.7'
services:
  kube_native:
    build: .
    depends_on:
      - postgres
    environment:
      DATABASE_URL: ecto://kube_native:kube_native@postgres/kube_native
      HOSTNAME: localhost
      PORT: 4000
      # mix phx.gen.secret
      SECRET_KEY_BASE: fzBk8OEcI8thGxlypWPUqfR2w2WopdN8v8pmpuy2JNj2eerbYFnlecuVMrFPGYnW
    ports:
      - 4000:4000

  postgres:
    image: postgres:10.5-alpine
    environment:
      POSTGRES_DB: kube_native
      POSTGRES_PASSWORD: kube_native
      POSTGRES_USER: kube_native
    ports:
      - 15432:5432
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data: {}
{{< /highlight >}}

We're specifying that this file should be parsed as Docker Compose's YAML
format with version `3.7` of the schema specifically, which requires Docker
`18.06` or newer. In this usage, we're not doing anything sophisticated and
it would be possible to migrate the file to an older standard without much
trouble. The compatibility matrix between Docker-Compose and Docker is
available [here](https://docs.docker.com/compose/compose-file/#compose-and-docker-compatibility-matrix). This same page describes all of the available keys in the
YAML schema as well as what values are acceptable for each, so it's a
valuable resource during our time with Docker-Compose.

Next up we start a YAML list of `services`, which are reflected as running
Docker containers after running commands such as `docker-compose up`.

{{< highlight yaml "linenos=table, linenostart=1" >}}
# https://docs.docker.com/compose/compose-file/
version: '3.7'
services:
{{< /highlight >}}


### Application Container {#application-container}

We define a **service** for the application itself, and tell it to build the
Docker image from the local working directory using the Dockerfile we
authored during [Part 1](/blog/2018/10/28/kubernetes-native-phoenix-apps-part-1/). This syntax also describes a logical dependency on
another **service** within this file, as our Phoenix app won't be very happy
without its database. This syntax will influence the order of operations
during the `docker-compose up` command and also ensure that the `postgres`
service is running whenever we try to start the `kube_native` service.

We set an environment variable named `DATABASE_URL` using [Ecto's URL
syntax](https://hexdocs.pm/ecto/Ecto.Repo.html#module-urls). The hostname can be `postgres` here because we're trying to reach a
sibling container that is defined within the same `docker-compose.yml`
file. The credentials are given in the form
`user:password@hostname/database_name`, prefixed with a pseudo-protocol of
`ecto://`, and we're going to preset those details in the Postgres
container farther down.

Matching the content from our [Other Conifguration and Secrets](#other-configuration-and-secrets) section
above, we've also set environment variables governing the hostname and port
the application should use in calculating its own URLs, and we've set a
`SECRET_KEY_BASE` with a fresh value provided by the `mix phx.gen.secret`
task. This last information should be considered sensitive and would not
typically be committed with the application's source, except perhaps in an
encrypted form.

Lastly, we expose the running application on the host machine (which will
be OSX itself for Docker For Mac users) on TCP port 4000 so that we can
contact it with a regular browser.

{{< highlight yaml "linenos=table, linenostart=4, hl_lines=6-10" >}}
kube_native:
  build: .
  depends_on:
    - postgres
  environment:
    DATABASE_URL: ecto://kube_native:kube_native@postgres/kube_native
    HOSTNAME: localhost
    PORT: 4000
    # mix phx.gen.secret
    SECRET_KEY_BASE: fzBk8OEcI8thGxlypWPUqfR2w2WopdN8v8pmpuy2JNj2eerbYFnlecuVMrFPGYnW
  ports:
    - 4000:4000
{{< /highlight >}}


### PostgreSQL Container {#postgresql-container}

We set some **insecure** but human-friendly values in the Postgres container
in order to pre-populate the existence of a database, and a less-privileged
user with a known password. These details were provided to Phoenix above
using the `DATABASE_URL` environment variable.

The `port` here demonstrates the syntax one would use to avoid port
collisions with existing Postgres installs on the host machine - the
Dockerized version will listen on `5432` within the container, but that
will be mapped to `15432` when considered from outside the container.

{{< highlight yaml "linenos=table, linenostart=17, hl_lines=4-6 9-10" >}}
postgres:
  image: postgres:10.5-alpine
  environment:
    POSTGRES_DB: kube_native
    POSTGRES_PASSWORD: kube_native
    POSTGRES_USER: kube_native
  ports:
    - 15432:5432
  volumes:
    - postgres-data:/var/lib/postgresql/data
{{< /highlight >}}


## Running Migrations and Seeds {#running-migrations-and-seeds}

The Distillery documentation has an excellent [guide on running migrations](https://hexdocs.pm/distillery/guides/running%255Fmigrations.html)
in a release context, where **we don't have access to any Mix tasks** or Mix
Elixir modules. The included snippet on that page can be adopted close to
as-is for our efforts.


### Migration Module {#migration-module}

Since we won't have Mix available for our trusty `ecto.migrate` task, we
need a relatively-pure Elixir approach that will provide similar behavior
without depending on Mix.

Very little of this content, derived from the [Distillery 2.0.12
documentation](https://github.com/bitwalker/distillery/blob/2.0.12/docs/guides/running%5Fmigrations.md), needed to change for either our specific application name or
Phoenix 1.4. At the time of writing, this code snippet currently doesn't
render correctly on HexDocs, but is [still available on GitHub](https://github.com/bitwalker/distillery/blob/2.0.12/docs/guides/running%5Fmigrations.md#migration-module).

{{< highlight elixir "linenos=table, linenostart=1, hl_lines=2 3-9 11 38" >}}
# apps/kube_native/lib/kube_native/release_tasks.ex
defmodule KubeNative.ReleaseTasks do
  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    :ecto_sql
  ]

  @repos Application.get_env(:kube_native, :ecto_repos, [])

  def migrate(_argv) do
    start_services()

    run_migrations()

    stop_services()
  end

  def seed(_argv) do
    start_services()

    run_migrations()

    run_seeds()

    stop_services()
  end

  defp start_services do
    IO.puts("Starting dependencies..")
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for app
    IO.puts("Starting repos..")
    Enum.each(@repos, & &1.start_link(pool_size: 2))
  end

  defp stop_services do
    IO.puts("Success!")
    :init.stop()
  end

  defp run_migrations do
    Enum.each(@repos, &run_migrations_for/1)
  end

  defp run_migrations_for(repo) do
    app = Keyword.get(repo.config, :otp_app)
    IO.puts("Running migrations for #{app}")
    migrations_path = priv_path_for(repo, "migrations")
    Ecto.Migrator.run(repo, migrations_path, :up, all: true)
  end

  defp run_seeds do
    Enum.each(@repos, &run_seeds_for/1)
  end

  defp run_seeds_for(repo) do
    # Run the seed script if it exists
    seed_script = priv_path_for(repo, "seeds.exs")

    if File.exists?(seed_script) do
      IO.puts("Running seed script..")
      Code.eval_file(seed_script)
    end
  end

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)

    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    priv_dir = "#{:code.priv_dir(app)}"

    Path.join([priv_dir, repo_underscore, filename])
  end
end

{{< /highlight >}}

I've set the overall module namespace to `KubeNative` to match our
application, and ensured that both `ecto` and `ecto_sql` appear in the list
of applications to start before executing the meaningful code. These two
entries also ensure that a new dependency introduced with Ecto 3,
`telemetry`, will be started, preventing any related errors.

{{< highlight elixir "linenos=table, linenostart=1, hl_lines=2-8" >}}
defmodule KubeNative.ReleaseTasks do
  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    :ecto_sql
  ]
{{< /highlight >}}

We also need to ensure that the code looks in the correct application's
configuration data to get the list of Ecto Repos that need to be present.

{{< highlight elixir "linenos=table, linenostart=10" >}}
@repos Application.get_env(:kube_native, :ecto_repos, [])
{{< /highlight >}}

As of Ecto 3, the connection pool needs to be at least `2` rather than `1`
with Ecto 2.

{{< highlight elixir "linenos=table, linenostart=30, hl_lines=8" >}}
defp start_services do
  IO.puts("Starting dependencies..")
  # Start apps necessary for executing migrations
  Enum.each(@start_apps, &Application.ensure_all_started/1)

  # Start the Repo(s) for app
  IO.puts("Starting repos..")
  Enum.each(@repos, & &1.start_link(pool_size: 2))
end
{{< /highlight >}}


### Custom Commands {#custom-commands}

We also need to create the two custom commands and enable them per the
[Distillery documentation](https://hexdocs.pm/distillery/extensibility/custom%5Fcommands.html).

We need one for migrations:

```shell
# rel/commands/migrate.sh

#!/bin/sh

release_ctl eval --mfa "KubeNative.ReleaseTasks.migrate/1" --argv -- "$@"
```

We also need one for seeds:

```shell
# rel/commands/seed.sh

#!/bin/sh

release_ctl eval --mfa "KubeNative.ReleaseTasks.seed/1" --argv -- "$@"
```

And we need to ensure that these scripts are packaged with the release:

```elixir
# rel/config.exs

# ...
release :kube_native_umbrella do
  # ...
  set commands: [
    migrate: "rel/commands/migrate.sh",
    seed: "rel/commands/seed.sh"
  ]
end

```


### Running The Migrations {#running-the-migrations}

Finally, we can put this into practice, so let's start our database and run
our migrations and seeds, both of which are currently empty.

```shell
docker-compose pull
docker-compose build --pull kube_native
docker-compose up -d postgres
docker-compose run --rm kube_native migrate
docker-compose run --rm kube_native seed
```


## Booting the application in Docker-Compose {#booting-the-application-in-docker-compose}

```shell
docker-compose up kube_native
```

You can then browse the application by visiting [http://localhost:4000](http://localhost:4000) as
normal, and should see the typical (production-style) log output in the
shell session that's running the above `docker-compose` command.

Note that this running container will not pick up any new file changes,
perform live-reload behavior, and is generally not useful for development
purposes. It's primary value is ensuring that your release is properly
configured via Distillery, and that your Dockerfile remains viable.


### Cleaning Up {#cleaning-up}

If you'd like to reset the database, or otherwise clean up after the
Docker-Compose environment, you can use the `down` subcommand, optionally
including a flag to clear the data volume as well. Without the flag, it
will still remove the containers and Docker-specific network that was
created for you.

```shell
docker-compose down --volume
```


## Code Checkpoint {#code-checkpoint}

The work presented in this post is reflected in git tag `part-2-end`
available [here](https://github.com/shanesveller/kube-native-phoenix/tree/part-2-end). You can compare these changes to the previous post [here](https://github.com/shanesveller/kube-native-phoenix/compare/part-2-start...part-2-end).


## Appendix {#appendix}


### Software/Tool Versions {#software-tool-versions}

| Software       | Version    |
|----------------|------------|
| Distillery     | 2.0.12     |
| Docker         | 18.06.1-ce |
| Docker-Compose | 1.22.0     |
| Ecto           | 3.0.1      |
| Elixir         | 1.7.4      |
| Erlang         | 21.1.1     |
| Phoenix        | 1.4.0      |
| PostgreSQL     | 10.5       |
