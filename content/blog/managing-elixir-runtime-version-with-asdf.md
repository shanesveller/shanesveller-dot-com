+++
title = "Managing Elixir runtime version with asdf"
author = ["Shane Sveller"]
date = 2017-12-23T22:30:00-05:00
lastmod = 2017-12-23T22:38:34-05:00
tags = ["asdf", "elixir", "erlang"]
categories = ["elixir"]
draft = false
+++

An uncomfortably common problem when developing for a particular programming
language is needing to deal with compatibility issues across different
versions of the language runtime. Most often this means keeping individual
projects tied to their then-current version of the language until such time
that the project can address any compatibility issues with later language
releases. To that end, Ruby developers are probably familiar with
one of `rbenv`, `chruby` or `rvm`, for example. Elixir isn't much different
in this regard.

<!--more-->

One available project that I find pretty promising is `asdf`, which is
self-described as:

> [An] extendable version manager with support for Ruby, Node.js, Elixir, Erlang & more

It fulfills some of the same roles that `rbenv` and friends do, while
supporting multiple languages and even other software tools in a fairly
standardized way.


## Installation {#installation}


### Homebrew {#homebrew}

```sh
brew install asdf
```

Follow the instructions in the output, which you can read again with `brew
     info asdf` if you missed them. As of this writing, those instructions are:

> Add the following line to your bash profile (e.g. ~/.bashrc, ~/.profile, or ~/.bash\_profile)
>
> `source /usr/local/opt/asdf/asdf.sh`
>
> If you use Fish shell, add the following line to your fish config (e.g. ~/.config/fish/config.fish)
>
> `source /usr/local/opt/asdf/asdf.fish`


### Git {#git}

You can follow the latest manual installation instructions from the
project's [README](https://github.com/asdf-vm/asdf/tree/8794210b8e7d87fcead78ae3b7b903cf87dcf0d6#setup), but today it includes:

```sh
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.4.0

# install shell hooks
# I personally prefer `source` to `.`

# bash users
echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bash_profile
echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bash_profile

# zsh users
echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.zshrc
echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.zshrc

# fish users
echo 'source ~/.asdf/asdf.fish' >> ~/.config/fish/config.fish
mkdir -p ~/.config/fish/completions; and cp ~/.asdf/completions/asdf.fish ~/.config/fish/completions
```


#### Prerequisites {#prerequisites}

At the time of writing, here are the prerequisites recommended to use
`asdf`, which can be installed with [Homebrew](https://brew.sh/):

```sh
brew install autoconf automake coreutils \
     libtool libxslt libyaml openssl \
     readline unixodbc
```


### Install required asdf plugins {#install-required-asdf-plugins}

You can check the available plugins, based on the open-source plugin index [here](https://github.com/asdf-vm/asdf-plugins):

```sh
asdf plugin-list-all
```

After identifying desirable plugins:

```sh
asdf plugin-install erlang
asdf plugin-install elixir
# phoenix users will likely also want:
asdf plugin-install nodejs
```


## Usage {#usage}

To install the latest Erlang and Elixir versions at the time of writing:

```sh
asdf install erlang 20.2
asdf install elixir 1.5.3
```

Phoenix users will also want:

```sh
asdf list-all nodejs
asdf install nodejs 9.3.0
```


### Checking available tool versions {#checking-available-tool-versions}

You can see what versions `asdf` currently supports for installation with
this command:

```sh
# asdf list-all [plugin]
asdf list-all erlang
asdf list-all elixir
asdf list-all nodejs
```

Each plugin is able to implement this behavior in its own way, so their
behavior may vary. Some are able to directly examine the releases of the
upstream language project, others require manual support within the `asdf`
plugin in question, and so may lag behind new releases.


### Installing a specific Erlang patch version {#installing-a-specific-erlang-patch-version}

The author of `asdf`, @HashNuke on GitHub, cleared up in [this GitHub issue](https://github.com/asdf-vm/asdf-erlang/issues/48#issuecomment-339137374)
that any tagged release of Erlang can be installed with `asdf-erlang`:

> We already support it. You can do the following:
>
> `asdf install erlang ref:OTP-20.1.2`
>
> Where OTP-20.1.2 is a valid tag that you can find on
> <https://github.com/erlang/otp/releases>. You can also specify a commit sha
> or branch name if you insist on the latest super-powers.

As of this writing the latest release is [20.2.2](https://github.com/erlang/otp/releases/tag/OTP-20.2.2), so that can be installed
like so:

```sh
asdf install erlang ref:OTP-20.2.2
# set global default
asdf global erlang ref:OTP-20.2.2
```


### Installing Elixir from `master` {#installing-elixir-from-master}

If you'd like to use the latest and greatest features, such as the
upcoming
[`mix
      format` command](https://github.com/elixir-lang/elixir/blob/v1.6/CHANGELOG.md#code-formatter) slated for inclusion in Elixir 1.6, you can install the
current version of the elixir-lang/elixir repository's `master` branch:

```sh
asdf install elixir master
```

You can use this version all the time via `asdf global` or `asdf local`,
or on one-off commands by setting the `ASDF_ELIXIR_VERSION` environment
variable to `master`.


### Per-project tool versions {#per-project-tool-versions}

By using `asdf local`, you can configure pre-project tool versions, which
are persisted in a project-local `.tool-versions` file you may wish to
include in your global `.gitignore`. When revisiting a project later, you
can run `asdf install` with no additional arguments to ensure that the
project's desired software versions are available.


## Keeping up to date {#keeping-up-to-date}

To update `asdf` itself:

```sh
asdf update
```

To update `asdf` plugins:

```sh
# update all plugins
asdf plugin-update --all
# update individual plugin
asdf plugin-update erlang
```


## Troubleshooting {#troubleshooting}

You can inspect where a particular version of a particular language is
installed with `asdf where`:

```sh
asdf where erlang 20.2
# /Users/shane/.asdf/installs/erlang/20.2
```

You can make sure that newly-installed binaries (such as those installed by
`npm`) are detected by using `asdf reshim`:

```sh
asdf reshim nodejs 9.3.0
# no output
```

You can inspect which specific binary will be used in your current context,
accounting for both global and local tool versions, with `asdf which`:

```sh
asdf which erlang
# /Users/shane/.asdf/installs/erlang/20.1/bin/erlang
```


## Alternatives {#alternatives}

There are many alternative options for
[installing Elixir](https://elixir-lang.github.io/install.html). Here are
a few in no particular order and with no specific endorsement:

-   Homebrew (`brew install erlang elixir node`)
-   [Nix package manager](https://nixos.org/nix/) and `nix-shell` (blog post forthcoming!)
-   [kiex](https://github.com/taylor/kiex) and [kerl](https://github.com/yrashk/kerl)


## Software/Tool Versions {#software-tool-versions}

| Software | Version |
|----------|---------|
| OSX      | 10.12.6 |
| asdf     | 0.4.0   |
| Elixir   | 1.5.3   |
| Erlang   | 20.2.2  |
| Node.js  | 9.3.0   |
