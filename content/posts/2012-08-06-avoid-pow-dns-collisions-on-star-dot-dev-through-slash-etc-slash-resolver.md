---
layout: post
title: "Avoid Pow DNS collisions on *.dev through /etc/resolver"
date: 2012-08-06T10:45:00-05:00
comments: true
categories:
- OSX
- Pow
---

At work, we use the `.dev` TLD for some internal services, staging servers, etc.
But I already use [pow](http://pow.cx/). What am I to do?

Turns out there's a super easy fix for my scenario. All our stuff at work is a
subdomain in the format of `foo.<company>.dev`, so this was all I had to do:

```
$ echo 'nameserver <DNS IP>' | sudo tee /etc/resolver/<company>.dev
```

Now Pow still works, but so do our internal services.
