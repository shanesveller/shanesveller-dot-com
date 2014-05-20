---
layout: page
title: "Shane Sveller"
date: 2013-07-10 19:30
comments: false
sharing: false
footer: true
---

# Quick Contents

* [Résumé](/downloads/resume.pdf)
* [Study Interests](#interests)
* [Pull Requests](#pr)
* [Blog Posts](#blog)
* [Works-in-progress](#wip)
* [Other examples](#other)
* [Desktop apps](#desktop) (unmaintained)
* [Web apps](#web) (unmaintained)

<a name="interests"/></a>
# Study Interests

I have a lot of interest in studying any of the following recreationally, so I
would definitely welcome an opportunity to expand my knowledge in these areas:

- [Docker](http://www.docker.io)
  - [Deis](http://deis.io/)
  - [CoreOS](https://coreos.com/)
- [RubyMotion](http://www.rubymotion.com/)
- [Ember.js](http://emberjs.com/)
- [Go](http://golang.org/)
- [Elixir](http://elixir-lang.org/)
- [Clojure](http://clojure.org/)
- [Graphite](http://graphite.readthedocs.org/en/latest/)
- [InfluxDB](http://influxdb.org/)

<a name="pr"/></a>
# Pull Requests

* [Update a Reddit image scraper to use the JSON API instead of HTML scraping](https://github.com/mbreedlove/Reddit-Image-Saver/pull/1)

* [Add CLI options to the same scraper using `optparse` from stdlib](https://github.com/mbreedlove/Reddit-Image-Saver/pull/2)

* [Add `spring` support alongside the `zeus` support in `guard-rspec`](https://github.com/guard/guard-rspec/pull/152)

* [Add `Vagrant` example to an `Ansible` playbook for testing](https://github.com/jlund/mazer-rackham/pull/1)

* [Update `rails_best_practices` to use current `ruby-progressbar` syntax](https://github.com/railsbp/rails_best_practices/pull/146)

* [Add `Ansible` deployment example to Joel's `thredded_app` repo](https://github.com/jayroh/thredded_app/pull/141) [In-progress]

<a name="blog"/></a>
# Notable Blog Posts

* [Using Docker transparently on OSX](/blog/2014/02/04/using-docker-transparently-on-osx/)
* [Local Gem Documentation With YARD, Pow and Alfred 2](/blog/2013/03/19/local-gem-documentation-with-yard/)
* [Avoid Pow DNS Collisions on *.dev Through /etc/resolver](/blog/2012/08/06/avoid-pow-dns-collisions-on-star-dot-dev-through-slash-etc-slash-resolver/)
* [1-month impressions of Sublime Text 2](/blog/2012/08/05/sublimetext-2/)

<a name="wip"/></a>
# Works-in-progress

* [Chef](http://www.getchef.com/chef/) cookbooks for VPS management, tested via
  [TestKitchen](http://kitchen.ci/), to be adapted from the foundation created
  [here](https://github.com/shanesveller/chef-challenges)
* [Docker](http://www.docker.io/)files for running various services and webapps
  [[Source](https://github.com/shanesveller/dockerfiles)]
* [Ansible](http://ansibleworks.com/) playbook for VPS management
  [[Source](https://github.com/shanesveller/ansible-vps-provisioner)]
* [Boxen](http://github.com/boxen/our-boxen) repo for laptop management
* [Octopress](http://octopress.org/)-based blog powering this site
  [[Source](https://github.com/shanesveller/shanesveller-dot-com)]

# Other Examples

## [Homebrew formulas](https://github.com/shanesveller/homebrew-brews/)

- [Exercism](http://www.exercism.io/) CLI [[Recipe](https://github.com/shanesveller/homebrew-brews/blob/master/exercism.rb)]

## Programming Puzzles

I've participated casually and sparingly in the programming puzzles at ProjectEuler, 4Clojure,
and [Exercism](http://exercism.io/shanesveller). Where possible, I've used the username
"shanesveller".

## Music Playlist Generator DSL concept

{% include_code playlist.rb lang:ruby change/playlist.rb %}

## [Boxen](http://github.com/boxen/our-boxen) manifest

{% include_code change/shanesveller.pp lang:text %}

<a name="unmaint"/></a>
# Unmaintained

<a name="desktop"/></a>
## Desktop Apps

* C#.Net tool for archiving and restoring [Dwarf Fortress](http://www.bay12games.com/dwarves/) saved games
  [[Homepage](http://df2010backup.codeplex.com/)]
  [[Source](http://df2010backup.codeplex.com/SourceControl/latest)]
  [[GitHub Mirror](https://github.com/shanesveller/df-backup-assistant)]

<a name="web"/></a>
## Web Apps

* Sinatra web app for generating "TinySong" links to play a song on Grooveshark
  [[Source](https://github.com/shanesveller/tinysinger)]

* [Padrino](http://www.padrinorb.com/) web app for choosing a class/spec in Rift MMO
  [[Demo](http://rift-picker.heroku.com/)]
  [[Source](https://github.com/shanesveller/rift-picker)]

## Ruby Library

* v2 API wrapper for WebbyNode using HTTParty, incomplete AVI coverage but
  well-documented. Tested with TestUnit.
  [[Source](https://github.com/shanesveller/webbynode-api)]

## Chrome Extension

* Pop-up extension for getting quick links to WoW character profiles on several companion sites
  [[Install from Web Store](https://chrome.google.com/extensions/detail/llafjcaincmipfpkggjidjbebigmoclc/)]
  [[Source](https://github.com/shanesveller/chrome-armory-links)]

## WoW Addon

* Remove character-based friends who are already present on your RealID friends list
  [[Source](https://github.com/shanesveller/real-id-clean)]
