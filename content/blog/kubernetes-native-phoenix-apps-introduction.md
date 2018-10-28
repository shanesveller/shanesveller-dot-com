+++
title = "Kubernetes Native Phoenix Apps: Introduction"
author = ["Shane Sveller"]
date = 2018-10-28T11:00:00-05:00
lastmod = 2018-10-28T11:36:59-05:00
tags = ["docker", "elixir", "phoenix", "umbrella", "kubernetes"]
categories = ["elixir"]
draft = false
+++

I'm kicking off a new blog series that focuses on the intersection of Elixir
and Kubernetes. This is becoming a more and more popular deployment target
for companies and developers who don't find a comfortable fit with [other
options](#alternate-deployment-tooling) that make different trade-offs.

I've spent most of the last two years helping several companies leverage
Kubernetes effectively, both as a direct employee on a systems/platform team
and as a specialized consultant, and I'd like to share some of those
learnings with the community that is nearest and dearest to my heart:
Elixir. These companies varied in size and scope, but their chief
commonality is that Kubernetes has proved to be an accelerant for their
business goals.

In particular, I consider Kubernetes an excellent target for deployment when
dealing with teams that are shipping polygot solutions, teams who are
managing multiple products without a dedicated team for each product,
organizations looking to achieve better infrastructure density or
standardization, or organizations who highly value infrastructure agility.

Elixir's deployment story has come a long way since I started working with
the language in 2015, but depending on your needs, there is still a **lot** of
information to assimilate, and a lot of practices to synthesize into a
unified, effective solution.


## Prerequisites {#prerequisites}

Infrastructure and deployment practices are not and can not be a
one-size-fits-all problem space, so I'm going to focus on presenting an
opinionated, focused, and polished approach that makes a few simplifying
assumptions:

-   You have at least one Elixir app that leverages Phoenix for a web
    interface
-   You are already using, prepared to upgrade to, or are otherwise capable of
    using Distillery 2.x in your project
-   You are deploying your product on one of the infrastructure-as-a-service
    platforms that are suitable for use with production-grade Kubernetes,
    such as:
    -   AWS via [Kops](https://github.com/kubernetes/kops)/[EKS](https://aws.amazon.com/eks/)
    -   GCP via [GKE](https://cloud.google.com/kubernetes-engine/)
    -   Azure via [AKS](https://docs.microsoft.com/en-us/azure/aks/)
-   Importantly, you **already have** a viable Kubernetes cluster in place with
    `kubectl` access ready to go
-   You are already comfortable with Kubernetes primitives or are capable of
    learning these from [another reference](https://kubernetes.io/docs/)


## Planned series content {#planned-series-content}

-   [Part 1](/blog/2018/10/26/kubernetes-native-phoenix-apps-part-1/)
    -   New [Phoenix](https://phoenixframework.org/) 1.4 project
    -   [Distillery](https://github.com/bitwalker/distillery/) 2
        -   [Configuration Providers](https://hexdocs.pm/distillery/config/runtime.html#config-providers)
        -   [Database Migrations/Seeds](https://hexdocs.pm/distillery/guides/running%5Fmigrations.html)
    -   [Multi-stage Docker build](https://docs.docker.com/develop/develop-images/multistage-build/)
        -   Dockerfile
        -   Dockerignore
        -   [Umbrella](https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-projects.html#umbrella-projects) support
        -   [Webpack](https://webpack.js.org/) assets
        -   Caching image stages
-   Part 2
    -   Running your application via [Docker Compose](https://docs.docker.com/compose/)
    -   Running migrations/seeds via Docker Compose
    -   Configuring secrets and runtime data via volumes
-   Part 3
    -   Building your image on [Minikube](https://github.com/kubernetes/minikube)
    -   [Helm](https://github.com/helm/helm) introduction
        -   Deploy [Postgres](https://www.postgresql.org/) via [community Helm chart](https://github.com/helm/charts/tree/master/stable/postgresql)
    -   Deploy your application via YAML
        -   Configuring runtime data via ConfigMap
        -   Configuring secrets vai Secret
        -   Expose your application via Service
    -   Running migrations/seeds via `kubectl exec`
    -   Running migrations/seeds via Job
-   Part 4
    -   Deploying your application via Helm
        -   [Helm-secrets](https://github.com/futuresimple/helm-secrets)
        -   [Helmfile](https://github.com/roboll/helmfile)
    -   Seeds during Helm install
    -   Migrations during Helm upgrades
-   Part 5
    -   Expose your application via Ingress
    -   Managing DNS with [external-dns](https://github.com/kubernetes-incubator/external-dns)
    -   Managing HTTPS with [cert-manager](https://github.com/jetstack/cert-manager/)
-   Part 6
    -   Clustering your application with [libcluster](https://github.com/bitwalker/libcluster)
    -   DNS- vs RBAC-based Kubernetes integration
    -   Phoenix PubSub / Channels / Presence
    -   ETS/Registry implications
-   Part 7
    -   Local HTTPS via `mix phx.gen.cert` or [mkcert](https://github.com/FiloSottile/mkcert)
    -   HTTP2 with [Cowboy 2](https://ninenines.eu/docs/en/cowboy/2.5/guide/)
    -   Exposing HTTP2 via Service
    -   HTTP2 Ingress ramifications
-   Part 8
    -   HTTP2 with [Istio](https://istio.io/)
-   Part 9
    -   Metrics with [Prometheus](https://prometheus.io/) and [Prometheus Operator](https://github.com/coreos/prometheus-operator)
    -   Visualization with [Grafana](https://grafana.com/) and [Grafanalib](https://github.com/weaveworks/grafanalib)/[Grafonnet](https://github.com/grafana/grafonnet-lib)
    -   Quality of service with Resource Request/Limits
    -   Cluster-wide resource constraints with LimitRange
-   Part 10
    -   Remote Observer via [Telepresence](https://www.telepresence.io/)


## Off-topic Subjects {#off-topic-subjects}

This series will avoid deep coverage of a few topics that are worthy
of their own separate coverage and will distract from the ideas being
presented here:

-   CI/CD practices or tooling recommendations - I've worked with almost all
    of them by now other than GoCD, and I've assumed the position that these
    needs are heavily informed by your organizational structure and tolerance
    for certain constraints or limitations, and aren't able to be addressed
    in a generalized way
-   Automating the actual deployment workflows from SCM - similar to the
    above, it's hard to cover this adequately in a generic way
-   Kubernetes-as-development-environment tools - Tools like [Draft](https://github.com/azure/draft), [Skaffold](https://github.com/GoogleContainerTools/skaffold/),
    Knative, along with some of the other features of Telepresence, don't
    currently offer a compelling use-case for me. I've attempted several
    iterations where I've tried to evaluate them in earnest, and I
    unfortunately found them to be feature-incomplete, unreliable, hard to
    triage without RTFS, and high-friction to use.

Additionally, I will avoid covering subjects that I consider to be
out-of-scope:

-   Elixir/Phoenix fundamentals
-   Elixir/Phoenix development environment
-   Kubernetes fundamentals
-   A direct treatment of the pros/cons of using containers with the BEAM
-   Individual merits of alternate container schedulers (K8s vs GKE/AKS/EKS
    vs OpenShift vs ECS vs Mesos vs Nomad)
-   Hot code upgrades in the context of Docker/Kubernetes


## Other Caveats {#other-caveats}

This series will avoid documenting certain practices that I strongly
consider to be development or deployment antipatterns. I'm aware that there
are some situations where they are more appropriate, or at very least more
expedient under the constraints in play, but these are generally to be
avoided if you have the opportunity to choose otherwise.

-   Long-term use of Docker images and long-lived containers as your actual
    development environment - stick with native development practices for
    best productivity
-   Single-stage Docker images which include a full development/compilation
    toolchain in the final product
-   Building Docker images **on** your Kubernetes cluster by mounting the
    Docker daemon's socket into a container (with a partial exception for the
    Minikube phase)
-   Raw YAML templates as a long-term solution for managing Kubernetes
    workloads
-   Tools such as Kompose which translate directly from `docker-compose.yml`
    to Kubernetes resource manifests
-   Namespaces and RBAC as your sole boundary between logical environments
    (such as dev/staging/production as implied by `MIX_ENV` conventions)


## Alternate Deployment Tooling {#alternate-deployment-tooling}

-   Platform-as-a-service offerings
    -   [Dokku](https://github.com/dokku/dokku)
    -   [Flynn](https://github.com/flynn/flynn)
    -   [Gigalixir](https://gigalixir.com/)
    -   [Nanobox](https://github.com/nanobox-io/nanobox)
    -   [Heroku](https://www.heroku.com/)
-   Imperative tools which espouse a Capistrano-like workflow
    -   [akd](https://github.com/annkissam/akd)
    -   [bootleg](https://github.com/labzero/bootleg)
    -   [edeliver](https://github.com/edeliver/edeliver)
    -   [gatling](https://github.com/hashrocket/gatling) (possibly unmaintained)
-   Specialized configuration management
    -   [ansible-elixir-stack](https://github.com/HashNuke/ansible-elixir-stack)
