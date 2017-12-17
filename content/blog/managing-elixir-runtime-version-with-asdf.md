+++
title = "Managing Elixir runtime version with ASDF"
author = ["Shane Sveller"]
lastmod = 2017-12-17T10:13:42-06:00
tags = ["asdf", "elixir", "erlang"]
categories = ["elixir"]
draft = true
+++

## Installation {#installation}

```sh
brew install asdf
```

Follow the instructions in the output, which you can read again with `brew info asdf`.

```sh
asdf plugin-list-all
asdf plugin-install erlang
asdf plugin-install elixir
asdf plugin-install nodejs
```


## Usage {#usage}

```sh
asdf install erlang 20.1
asdf install elixir 1.5.2
```


## Keeping up to date {#keeping-up-to-date}

```sh
asdf update
asdf plugin-update --all
```


## Benefits {#benefits}


## Alternatives {#alternatives}

-   Homebrew
-   Nix and `nix-shell` (blog post forthcoming!)


## Software/Tool Versions {#software-tool-versions}

| Software | Version |
|----------|---------|
| OSX      | 10.12.6 |
| asdf     | 0.4.0   |
| Elixir   | 1.5.2   |
| Erlang   | 20.1    |
| Node.js  | 8.9.0   |
