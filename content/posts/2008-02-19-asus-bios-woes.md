---
date: '2008-02-19T09:56:29-05:00'
layout: post
slug: asus-bios-woes
status: publish
title: ASUS BIOS woes
wordpress_id: '12'
categories:
- Computer Hardware
---

Yesterday I attempted to update the BIOS on my motherboard in anticipation of
eventually picking up an [Intel
E8400](http://www.newegg.com/Product/Product.aspx?Item=N82E16819115037). I
read on ASUS' website that the newest 45nm Intel CPUs are supported in the
latest BIOS revision, [1502](http://dlsvr03.asus.com/pub/ASUS/mb/socket775/Str
icker%20Extreme/SE1502.zip)/1503. 1502 was available on their [downloads
page](http://support.asus.com/download/download.aspx?SLanguage=en-us), so I
downloaded it and gave it a whirl. I was coming from what my motherboard
shipped with, revision 1203.  Now, my motherboard has a nifty LCD display on
the back that displays POST codes, letting me know where exactly it stops, if
and when it does. And it did.
<!--more-->
BIOS 1502 would not post in the rig I currently
have shown on my [Hardware](http://shanesveller.com/hardware) page. The LCD
displayed "`MSINSTAL`" indicating it stopped while attempting to "initialize
PS2 mouse", which I most assuredly do not have. It even did so with all
external hardware besides the monitor disconnected. After some investigation
on ASUS' forums that I probably should have been more thorough with _before_
performing the update, it turns out the issue is that 1502 doesn't correctly
support SLI, and won't even boot with two cards intalled. Removed the bridge,
pull out my second 8800GT, and off she goes. POSTed fine, was able to enter
the BIOS configuration, and even boot Vista and then XP.

But I'm not nearly ready to invalidate one hardware upgrade I've already
performed in advance of a potential one. So I got ready to downgrade. 1401
seemed to be the latest stable BIOS with good SLI support, so I downloaded it
from my laptop, put it on my flash drive, and popped the mobo CD into my
drive. Rebooted to the CD, ran their AWDFLASH utility with the `/f` flag to
allow a downgrade, and successfully reflashed my BIOS to 1402.

It's running just dandy now, including my SLI support. I also noticed a
setting in the BIOS that explained why my PC stayed "on" during standby. It
was doing what's known as Power-On Suspend rather than Suspend To RAM. Fixed
that setting, and now it powers down everything but a little juice to my
memory. Takes maybe 2 seconds longer to come back up, but it also goes dark
and silent.

