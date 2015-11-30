+++
categories = ["Homelab", "SmartOS"]
date = "2015-11-10T21:00:00-06:00"
tags = ["Lenovo", "TS140", "Joyent", "SDC", "SmartOS"]
title = "Homelab: SmartOS Lenovo TS140 build"
+++

Today I received the final component to complete my first homelab-specific PC build.<!--more-->

Here's the final spec sheet:

* [Lenovo ThinkServer TS140](http://www.amazon.com/Lenovo-ThinkServer-70A4001MUX-E3-1225v3-Desktop/dp/B00FE2G79C/) chassis 
* Intel Xeon E3-1225 v3 3.2GHz
* [32GB (4x8GB) Crucial ECC DDR3-1600](http://www.amazon.com/gp/product/B008EMA5VU)
* Western Digital Red 1TB 7200rpm (3)
* [Intel I340-T4 (PCIE 2.0 x 4 lane, 4x1Gb NIC)](http://www.amazon.com/Intel-Ethernet-Adapter-I340-T4-packaging/dp/B003A7LKOU)

The motherboard in this unit supports Intel AMT for lights-out management on the
on-board NIC.

I've installed Joyent's SDC, an enhanced, yet still open-source version of
[SmartOS](https://smartos.org/). This OS supports ZFS for storage, KVM
virtualization, as well as lighter-weight virtualization based on Solaris zones
that supports Linux via "LX-branded" zones. It offers API-driven image and
VM/zone creation, and will soon host a number of Linux VMs for my home use.

Both the on-board and the additional PCI-Express Intel NIC are supported, and
I've configured the 4-port NIC to be collected under non-LACP link aggegration
(neither active nor passive), and set this NIC as my `external` adapter while
the on-board NIC is the `admin` adapter. The `admin` adapter is used, among
other things, for PXE booting additional compute nodes. So far, this DHCP server
has not conflicted with my home router, despite not being physically isolated or
configured to use a VLAN.

Installation of SmartOS and later SDC was straightforward - simply flash an
image to a USB drive and boot from it - but initially I was missing one crucial
option. I needed to include `variable os_console vga` in the boot commands in
order to have viable keyboard input on a local console during the setup. My 3
SATA drives were automatically recognized and configured in a RAIDZ-1
arrangement for parity that allows for the loss of any one drive without
data loss. This is a fully-destructive operation, but I had originally used these
3 drives in a FreeNAS build prior to this and had nothing of value left on them.

Under vanilla SmartOS, I was shutting the unit down and re-flashing the USB to
upgrade to a new image, but since switching to the SDC distribution, I can do
this remotely and online via `sdcadm`. Since new releases come out every other
Thursday, I'm relieved to have a simpler option, as the USB drive I'm using is a
tiny form factor with roughly 2MB/sec sustained write speeds.

The learning curve for Solaris/SmartOS commands has been a little steep, but
[this guide](https://wiki.smartos.org/display/DOC/SmartOS+Command+Line+Tips) has
been invaluable. I've also added `pkgin` to the global zone so that I could
install `tmux`.



 
