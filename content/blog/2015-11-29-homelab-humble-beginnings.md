+++
categories = ["Homelab", "SmartOS"]
date = "2015-11-29T21:00:00-06:00"
draft = true
tags = ["Networking", "TP-LINK", "Ubiquiti", "UBNT", "Wireless"]
title = "Homelab: Humble Beginnings"
+++

I've expanded my home network recently with several bits of new commercial-grade
gear:

- TP-LINK TL-SG1016DE (16x1Gb "Easy Smart" switch)
- Ubiquiti EdgeRouter Lite (1x1Gb WAN, 2x1Gb LAN)

These are supplementing and somewhat replacing my existing router and repeater:

- ASUS RT-AC68U
- ASUS RT-N66U

My apartment is rather long and narrow, and my bedroom is at the fully opposite
end of it from the cable modem and AC router, so I added a second ASUS router
configured in Repeater mode to provide N service to the rear of the apartment. I
also tried Ethernet-over-Powerline, but even with the speed hit of repeater
mode, the wireless method was still faster. My desktop and laptop both have AC
NICs, but N is better than nothing until I move to a more suitable apartment or
upgrade to a second AC68U (or better).

The AC68U was switched to AP mode and its WAN port was wired into the TP-Link
switch, which has a line to the EdgeRouter port I've designated as one of the
two LAN lines. The EdgeRouter now does all external routing and will likely
serve as my VPN provider later on instead of my overworked Synology.

Both the EdgeRouter and TP-Link have good VLAN support, so I've enabled link
aggregration on each set of 4 ports used by my Synology and [TS140]({{< ref
"blog/2015-11-10-homelab-smartos-lenovo-build.md" >}}) respectively. I will start
experimenting with isolating some of the VMs via VLANs soon.

My goal with these devices was to enable more sophisticated techniques like
VLANs and link aggregration without alarming both my girlfriend and my wallet
with the higher prices of Cisco gear. I'm traditionally a fully cloud-native
infrastructure engineer for work, focusing entirely on Amazon AWS, but some
recent projects have me working adjacent to or directly on physical data center
projects, so more experience in those areas should help me both personally and
professionally.

Both devices offer web-based administration, and the router offers SSH
configuration as well. After spending no more than an hour with each, I'm
quite pleased with their responsiveness, UX/design and feature set.
