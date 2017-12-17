+++
title = "Blogging with org-mode and ox-hugo"
author = ["Shane Sveller"]
date = 2017-12-17
lastmod = 2017-12-17T10:30:34-06:00
tags = ["hugo", "org", "spacemacs"]
categories = ["emacs"]
weight = 3001
draft = true
+++

I've recently assembled a workflow for blogging with [Hugo](https://gohugo.io/), [org-mode](http://orgmode.org/), and
[Netlify](https://www.netlify.com/) via a single `.org` document, with live reload during writing and `git
    push` driven deployments.


## Requirements {#requirements}

I've detailed my current environment in the
[Software/Tool Versions](#ox-hugo-software-tool-versions) appendix below.
Strictly speaking, the hard requirements of the
[ox-hugo](https://melpa.org/#/ox-hugo) package are:

-   Emacs 24.4+
-   org-mode 9.0+

To use the `git`-based publishing part of this workflow, you'll also need:

-   A GitHub account (free or otherwise)
-   A Netlify account (free or otherwise)


## Features {#features}

-   Compose and organize content in a single Org file
-   Each post automatically gets a Table of Contents if sub-headings are present
-   Preview in your local browser including live-reload behavior
-   Syntax highlighting, including custom line numbers and line highlights
-   Manage draft / publication status
-   Manage categories and tags
-   Manage post aliases
-   Manage custom front-matter
-   Publish via `git push`, perhaps via [Magit](https://magit.vc/)
-   Free hosting via Netlify (dear Netlify, please let me give you money
    without a multi-user/Pro account!)
-   Free HTTPS via Netlify's Lets Encrypt integration


## Installation {#installation}

I've included snippets for `use-package` users and Spacemacs users - others
should look at the repository for the `ox-hugo` package for more
information.


### `use-package` Users {#use-package-users}

```emacs-lisp
(use-package ox-hugo
  :after ox)
```


### Spacemacs Users {#spacemacs-users}

Use <kbd> SPC f e d </kbd> to open `\~/.spacemacs` (or
`\~/.spacemacs/init.el`) and within the `dotspacemacs/layers` function, add or
update an entry to the `dotspacemacs-configuration-layers` list like so:

```emacs-lisp
(org :variables
     org-enable-hugo-support t)
```

Restart emacs or use <kbd> SPC f e R </kbd> to reload your
configuration on-the-fly. If you already have an entry for the `org` layer,
just include the variable `org-enable-hugo-support` with value `t`.


## Workflow {#workflow}


### File Structure {#file-structure}

There are several options for organizing the `.org` file you store your blog
posts and pages in, but here's one that works well for me. Some highlights
include:

-   Automatic export upon save as documented on the ox-hugo site
-   Manage multiple types of Hugo content from one file
    -   Manage traditional blog posts (`blog` type in my site)
    -   Manage static pages that disable most blog-like functionality (`page`
        type in my site)
-   Direct control of content ordering via `EXPORT_HUGO_WEIGHT: auto` - just
    change the order of your Org headings to reorder content on your Hugo
    site

<a id="org020b200"></a>
{{< highlight org "linenos=table, linenostart=1, hl_lines=3 4 7 9 10 21 33-37 43-47">}}
#+STARTUP: content
#+AUTHOR: Shane Sveller
#+HUGO_BASE_DIR: .
#+HUGO_AUTO_SET_LASTMOD: t
* Pages
  :PROPERTIES:
  :EXPORT_HUGO_CUSTOM_FRONT_MATTER: :noauthor true :nocomment true :nodate true :nopaging true :noread true
  :EXPORT_HUGO_MENU: :menu main
  :EXPORT_HUGO_SECTION: pages
  :EXPORT_HUGO_WEIGHT: auto
  :END:
** Page Title
   :PROPERTIES:
   :EXPORT_FILE_NAME: page-title
   :END:

   Page content

* Posts
  :PROPERTIES:
  :EXPORT_HUGO_SECTION: blog
  :END:
** Topic                                                             :@topic:
*** Post Title                                                    :post:tags:
    :PROPERTIES:
    :EXPORT_FILE_NAME: post-title-in-slug-form
    :END:

    Content

    More Content

    #+BEGIN_SRC bash -l 7 :hl_lines 8
      echo 'Some source code content'
      echo 'This line will be highlighted'
      echo "This one won't"
    #+END_SRC

**** Post Sub-Heading
     This is another section within the post.

* Footnotes
* COMMENT Local Variables                                           :ARCHIVE:
# Local Variables:
# eval: (add-hook 'after-save-hook #'org-hugo-export-wim-to-md-after-save :append :local)
# eval: (auto-fill-mode 1)
# End:
{{< /highlight >}}


## Bonus: Live reload without a separate shell tab {#bonus-live-reload-without-a-separate-shell-tab}

If you enable the `prodigy` layer in Spacemacs, or install the `Prodigy`
package manually, you can define a process in your
`dotspacemacs/user-config` function like so:

```emacs-lisp
(prodigy-define-service
  :name "Hugo Personal Blog"
  :command "/usr/local/bin/hugo"
  :args '("server" "-D" "--navigateToChanged" "-t" "hugo-redlounge")
  :cwd "~/src/shanesveller-dot-com"
  :tags '(personal)
  :stop-signal 'sigkill
  :kill-process-buffer-on-stop t)
```

Then, to manage the process while editing with Emacs, I use <kbd> SPC a
S </kbd> to open the Prodigy buffer, highlight the service entry, and
use <kbd> s </kbd> to start the process, <kbd> S
</kbd> to stop the service, and <kbd> $ </kbd> to
view process output. <kbd> q </kbd> will back out of any
Prodigy-generated buffers.


## Room for Improvement {#room-for-improvement}

-   Linking to headings, other posts, and headings in other posts
-   Emacs-lisp function to view Netlify preview URL
-   Emacs-lisp function to open your browser when opening the file and hugo is running
-   Screenshot capture workflow
-   Org-protocol workflow
-   Org-capture templates
-   CI workflow


## Software/Tool Versions {#ox-hugo-software-tool-versions}

| Software  | Version       |
|-----------|---------------|
| Emacs     | 25.3.1        |
| Spacemacs | 0.300.0       |
| Org       | 9.1.2         |
| Hugo      | 0.31.1        |
| ox-hugo   | 20171026.1402 |
| prodigy   | 20170816.1114 |
