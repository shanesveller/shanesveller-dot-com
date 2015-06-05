+++
categories = ["RubyGems", "Documentation", "Pow", "OSX", "Programming"]
comments = true
date = "2013-03-19T11:48:00-05:00"
layout = "post"
title = "Local Gem Documentation with YARD, pow and Alfred 2"

+++

I _love_ [rubydoc.info][rubydoc], but I was curious how hard it
might be to run a local copy. The site is powered by the [YARD gem][YARD].

You can use YARD to generate documentation for your installed gems, even if you
use `--no-rdoc` when running `gem install` (or have included it in your `.gemrc`,
as I have). This can be done by running `yard server --gems` and browsing to
http://localhost:8808/.

I already run [Pow][pow] on my MacBook, so I set up the `yard server` command to
run in the background via OSX LaunchAgents:

{% include_code '~/Library/LaunchAgents/YardDocs.plist' lang:xml YardDocs.plist %}

```
$ launchctl load -w ~/Library/LaunchAgents/YardDocs.plist
```

and then used the following to connect
it up with Pow and visit it in my browser:

```
$ echo '8808' > ~/.pow/gemdocs
$ open http://gemdocs.dev/
```

This uses Pow's [port forwarding][pow-port] functionality rather than the more
common Rack app usage. There was probably a way to implement this with a Rackup
file but the last time I investigated this, I was not able to find a Rack
configuration to run YARD's gem docs server.

Next, I set up a custom search in [Alfred 2][alfred] that allows me to look at the docs for
any gem by pressint Alt+Space, then typing "gemd &lt;gem name&gt;":

![Alfred 2 Custom Search](/images/2013-03-19-alfred2.png "Alfred 2 Custom Search")

If you have Alfred 2 installed, you can [click here][alfred2-search] to add this
search to your custom searches automatically.

[rubydoc]: http://www.rubydoc.info/
[YARD]: http://yardoc.org/
[pow]: http://pow.cx
[pow-port]: http://pow.cx/manual.html#section_2.1.4
[alfred]: http://alfredapp.com/
[alfred2-search]: alfred://customsearch/Gem%20Docs/gemd/utf8/noplus/http://gemdocs.dev/docs/{query}/frames
