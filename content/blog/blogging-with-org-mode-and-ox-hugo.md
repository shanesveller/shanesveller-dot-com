+++
title = "Blogging with org-mode and ox-hugo"
author = ["Shane Sveller"]
date = 2018-02-13T12:30:00-06:00
lastmod = 2018-02-13T12:28:03-06:00
tags = ["hugo", "netlify", "org", "spacemacs"]
categories = ["emacs"]
draft = false
+++

I've recently assembled a workflow for blogging with [Hugo](https://gohugo.io/), [org-mode](http://orgmode.org/), and
[Netlify](https://www.netlify.com/) via a single `.org` document, with live reload during writing and `git
    push` driven deployments.

<!--more-->


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
should look at the [repository](https://github.com/kaushalmodi/ox-hugo) for the `ox-hugo` package for more
information.


### `use-package` Users {#use-package-users}

```emacs-lisp
(use-package ox-hugo
  :after ox)
```


### Spacemacs Users {#spacemacs-users}

Use <kbd> SPC f e d </kbd> to open `~/.spacemacs` (or
`~/.spacemacs/init.el`) and within the `dotspacemacs/layers` function, add or
update an entry to the `dotspacemacs-configuration-layers` list like so:

```emacs-lisp
(org :variables
     org-enable-hugo-support t)
```

Restart Emacs or use <kbd> SPC f e R </kbd> to reload your
configuration on-the-fly. If you already have an entry for the `org` layer,
just include the variable `org-enable-hugo-support` with value `t`.


## Workflow {#workflow}


### Project Structure {#project-structure}

I'm working within a vanilla Hugo project with the following structure,
similar to what you'd see right after a `hugo new site` command:

```sh
$ tree -d -L 2
.
├── archetypes
├── content
│   ├── blog
│   └── pages
├── data
├── layouts
├── static
│   └── images
└── themes
    └── hugo-redlounge
```

My `blog.org` file sits at the root of my repository, but could be placed
nearly anywhere within and re-targeted with the `HUGO_BASE_DIR` setting.
Subtrees get exported to a subdirectory of `content` based on their
`EXPORT_HUGO_SECTION` property.


### File Structure {#file-structure}

There are several options for organizing the `.org` file you store your
blog posts and pages in, but here's a single-file structure that works
well for me.


#### Global settings and metadata {#global-settings-and-metadata}

{{< highlight org "linenos=table, linenostart=1" >}}
#+STARTUP: content
#+AUTHOR: Shane Sveller
#+HUGO_BASE_DIR: .
#+HUGO_AUTO_SET_LASTMOD: t
{{< /highlight >}}

Line 1 is an `org-mode` setting that tells Emacs that upon opening this
file, default to showing all headings and subheadings but not the inner
content until <kbd> TAB </kbd> is pressed while the
pointer is on a particular heading.

Line 2 sets my global author information, which propagates into each post
and page I manage with this `.org` file.

Line 3 tells `ox-hugo` that the current `.org` file is located in the
root of the overall Hugo project, which means that exported data will
be saved into the `content` directory and appropriate subdirectory that
reside next to the `.org` file. Relative and absolute paths both work here.

Finally line 4 tells `ox-hugo` to update the `lastmod` property of each
exported item to match the current time and date, which can be reflected
on your site in various ways based on your theme and configuration.


#### Creating a page {#creating-a-page}

{{< highlight org "linenos=table, linenostart=5" >}}
* Pages
  :PROPERTIES:
  :EXPORT_HUGO_CUSTOM_FRONT_MATTER: :noauthor true :nocomment true :nodate true :nopaging true :noread true
  :EXPORT_HUGO_MENU: :menu main
  :EXPORT_HUGO_SECTION: pages
  :EXPORT_HUGO_WEIGHT: auto
  :END:
{{< /highlight >}}

My `.org` file has a dedicated top-level Org heading to contain my `Page`
content, and this heading sets a number of shared **properties** that are
inherited by the individual sub-headings representing each page.

Line 7 includes multiple key-value pairs that get inserted as-is into the
[Hugo
front matter](https://gohugo.io/content-management/front-matter/#front-matter-variables). It largely disables all the "frills" one might typically
associate with a regular blog post - commenting, pagination, metadata, etc.

Line 8 indicates that Hugo should include a link to this content on the
`main` menu of my site, which is currently displayed on the left sidebar
of every page.

Line 9 tells `ox-hugo` to export the files into the `/content/pages`
subdirectory of my Hugo project, which has a slightly different Hugo
template file than a standard blog post.

Line 10 tells `ox-hugo` to manage the `weight` property of the Hugo
front matter data. It will calculate the appropriate relative numbers to
fill in during the export process.

{{< highlight org "linenos=table, linenostart=12" >}}
** Page Title
   :PROPERTIES:
   :EXPORT_FILE_NAME: page-title
   :END:

   Page content
{{< /highlight >}}

To create a new `page` on my Hugo site, I insert a new sub-heading under
the `Pages` heading from the snippet just above. That heading's title is
somewhat arbitrary, but this sub-heading will directly inform the `title`
of the exported content.

Line 14 demonstrates the first truly required property,
`EXPORT_FILE_NAME`, with tells `ox-hugo` what filename under
`/content/pages` to export this sub-tree to. Under my current settings
this also directly determines the actual path portion of the resulting
URL. For example, this one would be visible at `/pages/page-title/`.

Pages can include fairly arbitrary content below the sub-heading,
including further sub-headings to break up a longer page or post. You can
include links, images, and formatting, all using standard Org syntax.


#### Creating posts {#creating-posts}

{{< highlight org "linenos=table, linenostart=19" >}}
* Posts
  :PROPERTIES:
  :EXPORT_HUGO_SECTION: blog
  :END:
{{< /highlight >}}

As with Pages above, I create a top-level Org heading to contain my
standard blog posts.

Line 20 configures `ox-hugo` to export any sub-headings to
`/content/blog` in my Hugo project, versus `pages` above.

{{< highlight org "linenos=table, linenostart=23" >}}
** Topic                                                             :@topic:
{{< /highlight >}}

I sort my posts into categories by topic and create sub-headings for each
topic, and assign Org tags to each sub-heading that are prefixed with `@`.
Org tags on a post that have an `@` prefix will generate a `category`
entry in the exported front matter, which is one of the [default taxonomies](https://gohugo.io/content-management/taxonomies/#hugo-taxonomy-defaults)
built into a new Hugo project. Org tags are inherited from parent headings
by sub-headings, so all further subheadings under this subheading will
include the `@topic` tag.

{{< highlight org "linenos=table, linenostart=24" >}}
*** DONE Post Title                                               :post:tags:
    CLOSED: [2017-12-19 Tue 17:00]
    :PROPERTIES:
    :EXPORT_DATE: 2017-12-19
    :EXPORT_FILE_NAME: post-title-in-slug-form
    :END:
{{< /highlight >}}

This sub-heading begins a new post, and is marked as **DONE** in Org syntax
with a **CLOSED** timestamp. It also has Org tags named `post` and `tags`
which will be inserted into the exported front matter as `tags`. It
includes an `EXPORT_DATE` property, which would be used as the post's
publication date in the absense of the **CLOSED** timestamp on line 25.
Finally it includes the same `EXPORT_FILE_NAME` property as mentioned
above under Page management.

{{< highlight org "linenos=table, linenostart=31" >}}
Content

More content

#+BEGIN_SRC bash -l 7 :hl_lines 8
  echo 'Some source code content'
  echo 'This line will be highlighted'
  echo "This one won't"
#+END_SRC
{{< /highlight >}}

This snippet demonstrates the syntax needed to include a
syntax-highlighted code snippet within a post. You can quickly start a
code block with <kbd> < s TAB </kbd>.

If you append a valid language to `#+BEGIN_SRC`, and your copy of Emacs
has an associated major mode that is named `$language-mode`, you'll get
automatic syntax highlighting while composing the post, and the exported
markdown will include either the `highlight` [shortcode](https://gohugo.io/content-management/syntax-highlighting/#highlight-shortcode) or [Markdown "code
fences"](https://gohugo.io/content-management/syntax-highlighting/#highlight-in-code-fences). As an added bonus, you can use `org-edit-special` (<kbd>
, ' </kbd> for Spacemacs or <kbd> C-c ' </kbd>
for vanilla Emacs) to open a new popover window that lets you edit that
code snippet in a separate Emacs buffer. This will behave nearly
identically to editing a standalone file with that major mode, including
any extra behavior like auto-complete, linting, etc.


#### Excluding/heading sub-headings from export {#excluding-heading-sub-headings-from-export}

On some posts I like to create a private space to jot down ad hoc notes,
research and reference links, unrefined code snippets, etc. that
shouldn't appear in the final product but are useful to me during the
writing process. By configuring the `org-export-exclude-tags` variable,
or an `EXCLUDE_TAGS` file variable, then inserting a matching Org tag on
a sub-heading, that content will not appear in the exported Markdown or
in the published post, but will remain intact in the original `.org`
file. In my case, it's a `:noexport:` tag.


#### Automatic export on save {#automatic-export-on-save}

The ox-hugo site includes [great documentation](https://ox-hugo.scripter.co/doc/auto-export-on-saving/) for adding a local variable
to your `.org` file to enable automatic "what I mean" export whenever you
save the file.

The resulting syntax after following these instructions is:

{{< highlight org "linenos=table, linenostart=51" >}}
* Footnotes
* COMMENT Local Variables                                           :ARCHIVE:
# Local Variables:
# eval: (add-hook 'after-save-hook #'org-hugo-export-wim-to-md-after-save :append :local)
# eval: (auto-fill-mode 1)
# End:
{{< /highlight >}}


#### Full Sample {#full-sample}

{{< highlight org "linenos=table, linenostart=1, hl_lines=3 4 7 9 10 21 24-29 35-39 44 51-56" >}}
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
*** DONE Post Title                                               :post:tags:
    CLOSED: [2017-12-19 Tue 17:00]
    :PROPERTIES:
    :EXPORT_DATE: 2017-12-19
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

*** TODO Draft Post Title
    :PROPERTIES:
    :EXPORT_FILE_NAME: draft-post-title
    :END:

    This article *will* be exported but will be marked ~draft = true~ in the front matter.

* Footnotes
* COMMENT Local Variables                                           :ARCHIVE:
# Local Variables:
# eval: (add-hook 'after-save-hook #'org-hugo-export-wim-to-md-after-save :append :local)
# eval: (auto-fill-mode 1)
# End:
{{< /highlight >}}


### Marking a post as a Draft {#marking-a-post-as-a-draft}

To create a new draft post, add a new heading or subheading, and set it to
**TODO** status, perhaps via `M-x org-todo` or <kbd> C-c C-t
</kbd>.

**TODO** status ensures that the post will be rendered to Markdown with
`draft = true` in its frontmatter, which configures Hugo itself to prevent
a premature publish of the article to your live site unless specifically
instructed to include draft content.

_A heading without **TODO** or **DONE** is **not** considered a draft_.


### Publishing a Draft {#publishing-a-draft}

To publish a draft post, toggle its **TODO** state to **DONE**. If you have
`org-log-done` set to `'time`, toggling to **DONE** automatically adds a
**CLOSED:** timestamp that will be respected in favor of `EXPORT_DATE`
property for setting the `date` in the rendered post's front matter.


### Optional: Live reload without a separate shell tab {#prodigy-hugo-service}

If you enable the `prodigy` layer in Spacemacs, or install the `Prodigy`
package manually, you can define a process in your
`dotspacemacs/user-config` function like so:

{{< highlight emacs-lisp "linenos=table, linenostart=1" >}}
(prodigy-define-service
  :name "Hugo Personal Blog"
  :command "/usr/local/bin/hugo"
  :args '("server" "-D" "--navigateToChanged" "-t" "hugo-redlounge")
  :cwd "~/src/shanesveller-dot-com"
  :tags '(personal)
  :stop-signal 'sigkill
  :kill-process-buffer-on-stop t)
{{< /highlight >}}

Then, to manage the process while editing with Emacs, I use <kbd> SPC a
S </kbd> to open the Prodigy buffer, highlight the service entry, and
use <kbd> s </kbd> to start the process, <kbd> S
</kbd> to stop the service, and <kbd> $ </kbd> to
view process output. <kbd> q </kbd> will back out of any
Prodigy-generated buffers.


## Software/Tool Versions {#ox-hugo-software-tool-versions}

| Software  | Version       |
|-----------|---------------|
| Emacs     | 25.3.1        |
| Spacemacs | 0.300.0       |
| Org       | 9.1.2         |
| Hugo      | 0.31.1        |
| ox-hugo   | 20171026.1402 |
| prodigy   | 20170816.1114 |


## Emacs Lisp Snippets {#emacs-lisp-snippets}

Here's a snippet that can build off of [the Prodigy service snippet](#prodigy-hugo-service) to
automatically visit your local Hugo server in a browser once it's running.

I'm still learning emacs-lisp, and will probably find in the future that
this style doesn't suit me, particularly the trailing parentheses.

I'd also like to investigate `defcustom` to allow these default values to
be more configurable.

```emacs-lisp
(defun browse-hugo-maybe ()
  (interactive)
  (let ((hugo-service-name "Hugo Personal Blog")
        (hugo-service-port "1313"))
    (if (prodigy-service-started-p (prodigy-find-service hugo-service-name))
        (progn
          (message "Hugo detected, launching browser...")
          (browse-url (concat "http://localhost:" hugo-service-port))))))
```


## Credits {#credits}

Thank you to [Justin Nauman](https://twitter.com/jrnt30) for great feedback on an early version of this
article. Any remaining flaws are my own.
