+++
title = "Kubernetes Native Phoenix Apps: Series Discontinued"
author = ["Shane Sveller"]
date = 2019-10-31T11:38:00-05:00
lastmod = 2019-10-31T20:28:43-05:00
tags = ["elixir", "kubernetes", "phoenix"]
categories = ["elixir"]
draft = false
+++

It is clear to me and to everyone else that I have not completed the
ambitious outline I proposed at [the beginning of this series](/blog/2018/10/28/kubernetes-native-phoenix-apps-part-1/), and after
close to a full year of neglect, I feel I owe it to readers to be honest
about the fact that **no more posts in this series are forthcoming**.

<!--more-->

Due to a variety of personal factors, I have not been able to invest the
time, energy, and research necessary to continue to write posts in this
series while preserving the existing levels of accuracy and thoroughness.
Rather than compromise on the quality of the work, **I am discontinuing the
series** and do not intend to add more content or revise existing posts except
to correct any discovered security flaws.

Thank you very much to various commenters who have reached out here or
elsewhere with words of praise and encouragement, including the hopeful
queries about the next post. I'm sorry to let you down, but the most
rewarding feedback I can ever receive is that the information I shared has
helped you succeed.


## Outlook {#outlook}

In case anyone is curious, **I still believe Elixir is an excellent language
for developing networked services.** **I also still believe Kubernetes is an
excellent deployment target for such services.**

I was very grateful to see Jose Valim's _excellent_ post titled
[Kubernetes and the Erlang VM: orchestration on the large and the small](http://blog.plataformatec.com.br/2019/10/kubernetes-and-the-erlang-vm-orchestration-on-the-large-and-the-small/). It
is a great resource to help clear the air for people who suspected that
using one of the two obviated the need for or the benefits of the other,
from a respected voice.


## Hindsight {#hindsight}

Regarding the [original planned content](/blog/2018/10/28/kubernetes-native-phoenix-apps-introduction/#planned-series-content) for the series, I would probably
change a few things if I could, but the overall scope would remain largely
intact.

In this past June, [Elixir 1.9 introduced native support](https://elixir-lang.org/blog/2019/06/24/elixir-v1-9-0-released/) for building
releases without using Distillery, and while it doesn't do everything
Distillery supports, you may find it sufficient depending on your needs.

My previous employer has found great success in the usage of Job resources
for actions that need to occur once per logical deployment, such as
database migrations and seeds. Previously they were using `initContainers`
for this, which was an expensive repetition of work that was executed both
during deployments and during normal scale-up events in between deploys.

It has also been highly effective to expose system metrics using [Prometheus](https://github.com/deadtrickster/prometheus.ex)
together with instrumenting line-of-business code via the [telemetry](https://github.com/beam-telemetry/telemetry)
library. If you're curious what that looks like, my friend [Eric](https://twitter.com/ericoestrich) has a great
guide [here](https://blog.smartlogic.io/instrumenting-with-telemetry/).

On the "misses" side, I would avoid recommending people adopt Istio because
I think it's clear by now that most organizations do not need its
complexity and would find it difficult to reap much benefit. I think this
applies largely to all "Service Mesh" projects, but to Istio in particular.
If I felt I had a need that could be solved by Service Mesh, I'd
investigate [linkerd 2.x](https://linkerd.io/) instead.

Next, a word on tooling: Helm 3 is [around the corner](https://github.com/helm/helm/releases/tag/v3.0.0-rc.1) and comes with
[significant changes to the execution model](https://helm.sh/blog/helm-3-preview-pt2/) of the tool. Most people I've
spoken with are really optimistic about the security improvements that stem
from this change, but aren't looking forward to the migration process.
Meanwhile, [kustomize](https://kustomize.io/) has been gaining traction and some users are
considering it sufficient versus a more robust/complex templating solution.
Very-recent versions of the `kubectl` CLI even include native support for
Kustomize-based approaches.

Folks who are willing to explore more unconventional tools that are more
functional in approach may find [kubenix](https://github.com/xtruder/kubenix) or [dhall-kubernetes](https://github.com/dhall-lang/dhall-kubernetes) of interest.
Ksonnet was [cancelled outright](https://blogs.vmware.com/cloudnative/2019/02/05/welcoming-heptio-open-source-projects-to-vmware/) during VMWare's acquisition of Heptio
earlier this year. Jsonnet still exists, but I'm not seeing wide adoptions
in my little microcosm of the ecosystem.


## Still Have Questions? {#still-have-questions}

I really recommend you try posting on either the Elixir Forum, or the
[community Slack](https://elixir-slackin.herokuapp.com/) in #deployment and/or #kubernetes. There's a non-zero
chance I might be the one to see your question and respond! I am passionate
about the subject and do quite a bit of research and POCs to stay current,
but I am not unique in my expertise on this intersection, and getting input
from diverse viewpoints would be beneficial regardless.


## Up Next {#up-next}

A lot of my personal interests and professional focus have changed in the
last year, and I've delayed writing about any of them here due to the angst
about this unfinished series. Now that I've unburdened my conscience, I've
got a few areas that I might potentially touch on here as future blog
posts. I'm not committing to writing all or any of these, but this is the
list of topics that are tumbling around in my head.


### Kubernetes Operators {#kubernetes-operators}

Cory O'Daniel has a library called [bonny](https://github.com/coryodaniel/bonny/) for authoring Kubernetes
operators using Elixir itself, and some cursory exploration on my part
made me really optimistic about the project. Unfortunately, I don't have a
use-case for creating an internal operator today, and I would still be
strongly considering one of the Golang-based toolkits if I had to start
one in the next 3-6 months, as it would be the path of least resistance
(and most documentation).


### Elixir Docker Images {#elixir-docker-images}

The state of the official Elixir Docker images has caused me some personal
and professional grief over the years due to their use of mutable tags. As
an example, the image `elixir:1.9.2-alpine` might include various versions
of Erlang/OTP depending on when you first pulled the image. I've resorted
to pinning my `FROM` images with the full `image:tag@sha256:checksum`
syntax to counteract this.

I've been exploring performing "matrix" or cartesian-product Docker image
builds using the [Nix](https://nixos.org/nix/) language together with its direct support for
[producing Docker images declaratively](https://nixos.org/nixpkgs/manual/#sec-pkgs-dockerTools). This means I could readily build
images with the same essential content but including any specific pair of
Erlang and Elixir versions. The work necessary to support this also enables
the possibility of my replacing [asdf-elixir](https://github.com/asdf-vm/asdf-elixir) and [asdf-erlang](https://github.com/asdf-vm/asdf-erlang) with Nix-based
tooling instead.


### Nix {#nix}

On the topic of Nix, I have greatly expanded my use of the language and of
supporting tools like [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/rycee/home-manager). I'm down to roughly
&tilde;15 packages installed via [homebrew](https://brew.sh/) directly, and `home-manager`
maintains about &tilde;150 packages for me in its stead. I hope to share
some trip reports and snippets here in the future.


### Kubernetes-native CI {#kubernetes-native-ci}

I hope to examine some of the Kubernetes-native CI solutions that are
cropping up, such as [Tekton](https://tekton.dev/), because I'm not content with either Jenkins
or GitLab CI, who are currently dominating the self-hosted space. GitHub
Actions has also recently become generally-available and my initial
experiments are pretty positive, although there is _zero_ support for
caching at the moment.


### MUD Engine {#mud-engine}

I don't talk about it much because it's quite content-free and incomplete,
but like my friend Eric and other members of the [MUD Coders Guild](https://mudcoders.com/), I have a
nearly-from-scratch game engine for multiplayer text RPGs that I've been
working at off-and-on for the better part of two years. The ultimate goal
is to support the many magic systems of Brandon Sanderson's Cosmere book
universe, and to hopefully recapture some of the joy I experienced while
playing _Wheel of Time_ MUDs as a teenager.

I've recently started the MUD project over [yet again](https://www.commitstrip.com/en/2014/11/25/west-side-project-story/) to benefit from my
recent experience with building headless networked services, and I hope to
not repeat past mistakes, only make new ones! I previously burnt myself out
on the project by focusing on technically-challenging but less-rewarding
topics that were very low-level concerns, prior to incorporating actual
gameplay mechanics that would make it feel like a _game_. That said, it's
been a great testbed project for Distributed-Erlang techniques and other
libraries, and is where I first cut my teeth on `libcluster`.


### Rust {#rust}

In 2019 I have been revisiting my self-study of [Rust](https://www.rust-lang.org/). So far my favorite
Rust resource to keep my motivation up is a [tutorial for building
roguelike games](https://bfnightly.bracketproductions.com/rustbook/chapter%5F0.html) created by Herbert Wolverson, and this is a relatively
recent discovery for me. I also found the original edition and 2018
edition of _The Rust Programming Language_ to be one of the
highest-quality programming textbooks I've experienced thus far. I've made
exactly one appearance at our local Rust meetup in Chicago, and I hope to
hit up more as time allows.


### Haskell {#haskell}

I've also been very enthralled while studying [Haskell](https://www.haskell.org/), and Haskell has
exposed me to quite a bit of further computer-science research I hope to
do in the future. In particular, I picked up the _Purely Functional Data
Structures_ textbook by Chris Okasaki, _Thinking With Types_ by Sandy
Maguire, and early access to _Optics By Example_ by Chris Penner via his
[Patreon](https://www.patreon.com/ChrisPenner). I'm still working through all of them but I feel like I'm
learning and appreciating so much already.


### Self-Care {#self-care}

Around the beginning of the year I started to experience moderate RSI
symptoms and made some equipment changes to counteract the pain. I switched
to using an [Ergodox EZ](https://ergodox-ez.com/) keyboard at work and at home, as well as a [Logitech
MX Vertical](https://www.logitech.com/en-us/product/mx-vertical-ergonomic-mouse) mouse at the office, and I consider them both to be successful
as I have been pain- and numbness-free for months. There is a definite
adjustment period to both, and it unfortunately means my home-office desk
is less-than-useful to my partner if she wished to use it on occassion. I
might one day write up some of my conceptual decisions in how to structure
my keyboard layout, how I manage it technically, the advantages offered by
a keyboard with programmable firmware, and gotchas to look out for.


### Non-technical Hobbies {#non-technical-hobbies}

My partner is currently embarking on the journey to read my beloved _Wheel
of Time_ book series, and I have re-read it so often (once per book release
of the final four entries) that I needed a way to keep things fresh while
also following along with her progress. I've never consumed books in
audiobook form before, but Michael Kramer and Kate Reading have
well-deserve reputations for enriching [the experience](https://www.audible.com/series/Wheel-of-Time-Audiobooks/B005NB81EI). I've had a fresh
sense of enjoyment from revisiting such familiar stories this way, and
they're a sure-fire way to elevate my mood on a melancholy day. I'm looking
forward to and/or dreading the launch of [Amazon's TV adaptation](https://twitter.com/wotonprime) and the
inevitable comparisons to ASOIAF/Game of Thrones, even though the WoT
series is older, **finished**, and IMHO, executed much better.

I'm also a giant sucker for the _Star Wars_ franchise, which has a
[startling amount of content coming out next month](https://twitter.com/StarWarsExplain/status/1189943612576059393). I've read a non-trivial
fraction of the available EU material, most of the new canon through 2018,
and am currently working my way through several of the classic and modern
comic series as well. We also recently attended our third annual
performance of the original trilogy movies with the music performed
by a live orchestra, in Kalamazoo, MI. It's been a great trip every year.

In a shocking turn of events for a household of two software developers, we
play a fair amount of board games, and I'm particularly looking forward to
starting a [Gloomhaven](http://www.cephalofair.com/gloomhaven) campaign with friends early next year. We also had
our first session of the _Sherlock Holmes: Consulting Detective_ game
series a little while back, which I loved, partially because we picked a
great group to play it with. Old standbys like _Century: Spice Road_ and
_Roll for the Galaxy_ still make frequent appearances, too. I have
aspirations of making some digital utilities to improve our tableside
experiences in the future, particularly for RPG campaigns.
