+++
title = "Spaced repitition with org-drill"
author = ["Shane Sveller"]
date = 2017-12-17
lastmod = 2017-12-17T10:29:58-06:00
tags = ["education"]
categories = ["emacs"]
draft = false
+++

My team at [work](https://www.raise.com/) has previously used
[org-drill](http://orgmode.org/worg/org-contrib/org-drill.html) to study
less-familiar subjects, initially focused on Kubernetes during our early
adoption process. Its documentation is largely excellent, but here's a few
extra details we've learned over time.


## Installation {#installation}

```emacs-lisp
(with-eval-after-load 'org
  (require 'cl)
  (require 'org-drill))
```


## Usage {#usage}


### Creating cards {#creating-cards}


#### Single File {#single-file}

Here's what the raw `org` source looks like:

```org
* Cards

** Card 1                                                             :drill:

*** Card 1 Answer
```


#### Directory of Files {#directory-of-files}


## Software/Tools Versions {#org-drill-software-tools-versions}

| Software  | Version |
|-----------|---------|
| Emacs     | 25.3.1  |
| Spacemacs | 0.300.0 |
| Org       | 9.1.2   |
