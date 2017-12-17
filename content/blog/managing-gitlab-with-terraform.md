+++
title = "Managing GitLab groups and projects with Terraform"
author = ["Shane Sveller"]
date = 2017-12-17T11:26:00-06:00
lastmod = 2017-12-17T11:29:15-06:00
draft = false
+++

## Configuring the provider {#configuring-the-provider}

The following Terraform syntax can be used with the public/commercial
GitLab.com service or with a self-hosted installation, as long as you have
network connectivity and a token with the correct permissions. I'm using
the latter.

In my case, I used a **Personal Access Token** associated with my individual
administrative account, with these permissions:

-   `api`
-   `read_user`

```hcl
variable "gitlab_token" {
  type    = "string"
  default = "hunter2"
}

variable "gitlab_url" {
  type    = "string"
  default = "https://gitlab.mydomain.com/api/v4/"
}

provider "gitlab" {
  base_url = "${var.gitlab_url}"
  token    = "${var.gitlab_token}"
  version  = "~> 1.0.0"
}
```

If you'd like to keep these out of your source code, Terraform also allows
setting variables in shell environment variables by prefixing them with
`TF_VAR_`, as in `TF_VAR_gitlab_token` and `TF_VAR_gitlab_url`. You can
manage these manually or with a tool like [direnv](https://direnv.net/),
and keep the latter's `.envrc` file in your `.gitignore`.


## Creating a group {#creating-a-group}

```hcl
resource "gitlab_group" "blogs" {
  name        = "blogs"
  path        = "blogs"
  description = "Public blog repositories"
}
```


### Creating a nested group {#creating-a-nested-group}

I have a group on my GitLab site for `infrastructure` projects, and a
nested group on my site for [Helm](https://helm.sh/) charts within that `infrastructure`
group. Here's the Terraform code that manages those two groups and their
relationship:

```hcl
resource "gitlab_group" "infrastructure" {
  name        = "infrastructure"
  path        = "infrastructure"
}

resource "gitlab_group" "helm-charts" {
  name        = "helm-charts"
  path        = "helm-charts"
  parent_id   = "${gitlab_group.infrastructure.id}"
}
```

Projects created within this child group will appear on the site at
paths that look like `/infrastructure/helm-charts/foo-chart`.


## Creating a project within a group {#creating-a-project-within-a-group}

Here's an example, a mirror of my public blog that is hosted on GitHub as
well. Because of the nature of its contents, I've disabled most of the
extra features offered by GitLab for this particular repository.

{{< highlight hcl "hl_lines=2 7">}}
resource "gitlab_project" "blogs-shanesveller-dot-com" {
  name                   = "shanesveller-dot-com"
  default_branch         = "master"
  description            = ""
  issues_enabled         = false
  merge_requests_enabled = false
  namespace_id           = "${gitlab_group.blogs.id}"
  snippets_enabled       = false
  visibility_level       = "public"
  wiki_enabled           = false
}
{{< /highlight >}}

With the highlighted lines in place, the repository path on the site
becomes `/blogs/shanesveller-dot-com`.


## Closing Comments {#closing-comments}

The GitLab provider as of 1.0.0 is missing some API coverage for what
GitLab offers, and has some bugs associated with things like a project's
default branch. Often I use `git-flow` and want to set a project's default
branch to `develop`, but that feature does not currently seem to work
reliably due to
[this
code typo](https://github.com/terraform-providers/terraform-provider-gitlab/pull/41).


## Software/Tools Versions {#gitlab-terraform-software-tools-versions}

| Software                  | Version |
|---------------------------|---------|
| GitLab                    | 10.2.4  |
| Terraform                 | 0.10.7  |
| Terraform GitLab Provider | 1.0.0   |
