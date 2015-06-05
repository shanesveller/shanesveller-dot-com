---
date: '2008-04-24T14:39:16-05:00'
layout: post
slug: quick-tip-ubuntu-default-runlevel
status: publish
title: 'Quick Tip: Ubuntu default runlevel'
wordpress_id: '21'
categories:
- Linux
- Ubuntu
---

If you, like me, use `sysv-rc-conf` to change the services that run a
particular runlevel, i.e. so that runlevel 2 is actually only networked and
not GUI as tradition holds, you can set the default runlevel to boot in Ubuntu
by editing:

{% codeblock /etc/inittab %}
id:3:initdefault
{% endcodeblock %}

The number in the middle is the runlevel to start by default.

