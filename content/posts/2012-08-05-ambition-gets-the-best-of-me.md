---
layout: post
title: "Ambition gets the best of me"
date: 2012-08-05T19:21:00-05:00
comments: true
categories:
- Programming
- iOS
- RubyMotion
- Ruby on Rails
- Projects
---

Recently I splashed on a [RubyMotion](http://www.rubymotion.com/) license, and
I've been itching to put it to good use as soon as I got my grubby little hands
on it.

I've got a use-case I might be able to work with at my job for an internal service,
but since our VPN client keeps crashing my Mac Mini due to a Mountain Lion incompatibility,
I'm searching for something I can do at home.

So, I'm seriously considering setting out on the journey of developing a Ruby on
Rails-powered blog engine and its accompanying read-write iOS client app in parallel, as a learning
experience only.

Given my track record, I wouldn't hold my breath on the results showing polish,
or you know, completion.

<!-- more -->

If I manage to stick through it, this will give me lots of learning opportunities,
including but not limited to the following:

## Rails

* File/image uploads
    * Preferably AJAX
    * Preferably to Amazon S3
    * Thoughtbot's recently released [jack_up](https://github.com/thoughtbot/jack_up) gem looks great
* Polymorphic associations
    * Tagging system
    * Comments system
* JSON API from the server side
    * Grape
    * Active_record_serialization
* Zurb Foundation
* Responsive design

## iOS

* iOS basic architecture
* RubyMotion workflow
* CocoaPods usage
* JSON API from the client side
    * [BubbleWrap](http://bubblewrap.io)
    * RestKit
* Deploying test versions using TestFlight or ad-hoc deployment
