+++
title = "Kubernetes Native Phoenix Apps: Part 3"
author = ["Shane Sveller"]
date = 2018-11-16T12:25:00-06:00
lastmod = 2018-11-16T13:40:14-06:00
tags = ["docker", "elixir", "helm", "phoenix", "umbrella", "kubernetes"]
categories = ["elixir"]
draft = false
+++

Now that we've established a viable workflow for building and running our
application in Docker containers, it's time to take our first pass at
running those containers on Kubernetes!

<!--more-->

Published articles in this series:

-   [Introduction](/blog/2018/10/28/kubernetes-native-phoenix-apps-introduction/)
-   [Part 1](/blog/2018/10/28/kubernetes-native-phoenix-apps-part-1/)
-   [Part 2](/blog/2018/11/13/kubernetes-native-phoenix-apps-part-2/)
-   Part 3 (this post)

To test our application in a Kubernetes environment, we have two available
routes: we can publish our Docker images to a public or private Docker
registry, and then deploy those images to a "real" cluster, or we can use
[Minikube](https://github.com/kubernetes/minikube) and build our images directly on the Minikube VM. For illustrative
purposes, let's start with the latter approach first.

As a reminder of what I wrote in the Introduction post, we will be glossing
over a lot of Kubernetes/Elixir/Phoenix fundamentals in this series and
trying to refer to existing documentation as often as possible. The purpose
of this series is more oriented around synthesizing a working solution from
disparate learnings. If you have unanswered questions, please feel free to
leave a comment and I'll try to direct you to the right learning resources.


## Building Docker images for Minikube {#building-docker-images-for-minikube}

I'm using a [mildly customized Minikube configuration](#preferred-minikube-config) that more closely
matches my long-term target environment, which is [Google Container Engine](https://cloud.google.com/kubernetes-engine/).
However, one of the powerful benefits of targeting Kubernetes as a platform
is that the the content below is, for most purposes, compatible across many
different cloud providers as long as you're running a conformant cluster.

To build Docker images for Minikube specifically, we can directly re-use
the Docker daemon that is installed as part of the Minikube virtual
machine. This method can be very expedient, but is not compatible with a
"real" cluster, so we will need another path forward later on in the
series.

First, we use `eval` to set some environment variables that tell the local
`docker` CLI, perhaps the one included with Docker For Mac, how to talk to
the VM's Docker daemon. You don't need the actual Docker for Mac
application running to use this technique, but you do need to have it
installed. If you're using my specific Minikube config, you'll also want to
install the Hyperkit driver [as documented by the Minikube project](https://github.com/kubernetes/minikube/blob/v0.30.0/docs/drivers.md#hyperkit-driver).

After using the `eval` command, most if not all standard Docker CLI
subcommands should work correctly, so you can use `ps` to inspect running
containers (and get a glimpse of the inner structure of a Pod), or `images`
to inspect locally available Docker images. You can obtain extra images
with `pull` or `build`, and so on. In our case, we're going to use `build`
to construct our local image for our [application](https://github.com/shanesveller/kube-native-phoenix), which will then be
available to the Kubernetes scheduler for use with Pods later on.

```shell
eval $(minikube docker-env)
docker build -t kube-native:latest .
```

At the time of writing, we can't use `docker-compose` directly with Minikube
due to version incompatibilities, but we could ostensibly use `docker run`
with some extra arguments to match the container definition from our
`docker-compose.yml` file. However, this knowledge doesn't transfer
especially well into Kubernetes usage, and won't integrate at all with the
networking abstractions provided by Service objects, so I will leave that
step as an optional exercise for the reader.


## A taste of Helm {#a-taste-of-helm}

In order to successfully deploy our application, we need access to a
PostgreSQL database. There are a lot of avenues available to us, including
managed offerings like [Amazon RDS](https://aws.amazon.com/rds/) or [Google Cloud SQL](https://cloud.google.com/sql/docs/). Those services are
definitely where I would direct most people for production purposes.
Running your own highly-available database is challenging, isn't
particularly differentiating for most businesses, and isn't within most
organization's core competencies. Doing so within a containerized
environment is still more challenging, and usually isn't recommended.

Later on in this series, we'll touch on the topic of "controllers" and
"operators" for Kubernetes, which can distill and embody human expertise to
make managing containerized software more successful. Among those available
tools are a few options for managing containerized databases. We likely
won't tackle that specific example directly, but we will definitely
leverage a few of the other operators.

For our purposes, all we specifically care about at the moment are that
there is a database available for our use, and that our running Pods can
connect to it. Since we're not being picky about the other details, let's
go ahead and run a database on our Kubernetes cluster anyway.

We could synthesize the necessary Kubernetes YAML to do so on our own, but
we're about to do that for our in-house application in another section of
this post, so let's use the "off-the-shelf" approach made possible by the
community tool [Helm](https://github.com/helm/helm). The Helm user community contributes a fairly robust
body of packages for use with Helm, called Charts, which are available on
[GitHub](https://github.com/helm/charts). Later on in the series, we'll be authoring our own Chart for our
application.


#### Helm Glossary {#helm-glossary}

Tiller
: server-side component of the Helm suite, which runs
    on-cluster and interacts with the Kubernetes API on our
    behalf

Helm
: CLI component of the Helm suite, which communicates with Tiller
    via gRPC

Chart
: a package of templatized Kubernetes YAML which can be managed
    via Helm/Tiller to provide functionality to your cluster, or
    to your customers

Repository
: Collection of Helm charts made available directly for use
    via the Helm CLI

Release
: an instantiated/deployed copy of a Chart, which represents a
    collection of Kubernetes resources and can be managed in an
    ongoing fashion with the Helm CLI for upgrades, rollbacks,
    and deletion


#### Installing Tiller {#installing-tiller}

Helm needs a server-side component named Tiller, and there's a lot of
reading to be done about how to manage this component safely and securely
for production use, and the practices there will likely change drastically
when Helm v3 releases in the next year or two. This example configuration
does **not** include TLS support and uses cluster-wide administrative
privileges, so it is not particularly reflective of good production
practices.

For more information, see the Helm documentation around [RBAC](https://docs.helm.sh/using%5Fhelm/#role-based-access-control), [TLS](https://docs.helm.sh/using%5Fhelm/#using-ssl-between-helm-and-tiller), and
[general security models](https://docs.helm.sh/using%5Fhelm/#securing-your-helm-installation). Angus Lees of Bitnami also wrote [a really nice
piece](https://engineering.bitnami.com/articles/helm-security.html) about hardening Helm.

We need a ServiceAccount for Tiller to use in its API calls, and that
ServiceAccount needs to have administrative privileges on the cluster. We
also don't want to keep an unbounded amount of history around for Helm
releases, so we cap that at 10 historical versions per Release.

```shell
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller \
        --clusterrole cluster-admin \
        --serviceaccount=kube-system:tiller
helm init --history-max 10 \
     --service-account tiller \
     --skip-refresh --upgrade --wait
```


#### Installing PostgreSQL {#installing-postgresql}

Public repositories of Helm Charts can be managed through the `helm repo`
subcommands, and we need to make sure that the "stable" repository, which
matches the content of the `helm/charts` GitHub repository, are available
for use.

```shell
helm repo add stable https://kubernetes-charts.storage.googleapis.com
```

Then, we're going to look at what configuration options, or Values, are
included with the Chart we want to use. Much like other content in the
Kubernetes ecosystem, these are always rendered and authored using the
YAML format. Many Charts have fairly descriptive names and even
documentation comments on their Values files, but you ultimately may need
to visit the Chart's README or even peruse the source of the Chart to
determine exactly what tunable variables are available and what values
are acceptable to use.

```yaml
helm inspect values stable/postgresql --version 0.19.0
```

Finally, after identifying the immediately-relevant settings from the
Values data, we're going to tweak some of those Values as part of the
`helm install` command that is used to deploy the PostgreSQL container.
The first pass uses the flags `--debug` and `--dry-run` to emit the
generated YAML to STDOUT for inspection, then the command is repeated
without those flags in order to actually enact the changes. A `--wait`
flag is included in order to block the completion of the command until
those new resources are fully ready. Later on we'll see how a tool called
`helmfile` can expedite this inspect-and-approve workflow.

```shell
helm install stable/postgresql \
     --name kube-native-postgresql \
     --namespace kube-native \
     --set-string imageTag=10.5-alpine \
     --set-string postgresUser=kube_native \
     --set-string postgresDatabase=kube_native \
     --set-string postgresPassword=kube_native \
     --version 0.19 \
     --debug --dry-run
helm install stable/postgresql \
     --name kube-native-postgresql \
     --namespace kube-native \
     --set-string imageTag=10.5-alpine \
     --set-string postgresUser=kube_native \
     --set-string postgresDatabase=kube_native \
     --set-string postgresPassword=kube_native \
     --version 0.19 \
     --wait
```

You'll notice that I'm choosing a particular, and rather outdated,
version of the Chart in the commands above. That's because in the pre-1.0
series of this chart, its functionality was based directly on the
official `postgres` Docker image from [Docker Hub](https://hub.docker.com/%5F/postgres/). Later iterations of the
chart, particularly the 1.x and 2.x series, made drastic changes to both
the Values schema and to the base image, which was moved to [a
Bitnami-managed image](https://github.com/bitnami/bitnami-docker-postgresql).

In my recent experiences, these newer Chart versions and the Bitnami
image were both somewhat brittle and proved to be fast-moving targets,
while the 0.x series of the Chart and the official Hub image have proved
satisfactory for several months. I opted for a lower maintenance burden
for the purposes of this series.

> Note that release names and namespaces both cannot contain underscores,
> only hyphens.

If we want to perform a quick sanity check of our new database, we can
use `kubectl port-forward` to connect to it directly with the
preconfigured credentials.

```shell
# straight from the Helm chart's install notes
# helm status kube-native-postgresql
export POD_NAME=$(kubectl get pods --namespace kube-native -l "app=postgresql,release=kube-native-postgresql" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace kube-native $POD_NAME 15432:5432

# new shell session
psql postgres -U kube_native -p 15432 -h localhost
\l
\q
```


## Describing our application on Kubernetes' terms {#describing-our-application-on-kubernetes-terms}

Now that we have a viable database to work with, let's set about actually
running our application using standard Kubernetes primitives and unadorned
YAML. We'll introduce some more refined workflows and tools later in the
series.


### ConfigMap {#configmap}

First up is creating a home for our non-sensitive configuration details
that are supplied via environment variables. We set the stage for the
Elixir side of this 12-factor-ish configuration style [back in Part 2](/blog/2018/11/13/kubernetes-native-phoenix-apps-part-2/#other-configuration-and-secrets).

These values are intentionally very similar to what we included in
the `docker-compose.yml`'s `environment` block for the application
container.

Farther down in the Deployment manifest, you'll see that each entry within
`data` appears within the container as an environment variable with the
same name and the associated value, via `envFrom`. As all environment
variables in the Deployment manifest must be strings, we have to quote any
ambiguous values that could be inferred as another value type.

{{< highlight yaml "linenos=table, linenostart=1" >}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-native-env
  labels:
    app: kube-native
    data:
      HOSTNAME: localhost
      # cannot be a YAML number, thus the quotes
      PORT: "4000"
      # cannot be a YAML boolean true, thus the quotes
      REPLACE_OS_VARS: "true"
{{< /highlight >}}

We instantiate this ConfigMap with `kubectl apply`:

```shell
kubectl apply -n kube-native -f configmap.yaml
```


### Secret {#secret}

We also already have a few pieces of sensitive information that need to be
supplied as environment variables as well, and for that we'll use a
Kubernetes Secret. It's worthwhile to remind readers that Secrets are not
without flaws, and chief among them is that their YAML representation
isn't truly encrypted, merely a base64 encoding of their contents.
Permissions for accessing a Secret are essentially only constrained by
your cluster's RBAC rules, and anyone with a `cluster-admin` Role can
essentially read any Secret they like. It also takes [a fair amoung of
extra effort](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) to ensure that both your `etcd` data and Secrets data within
etcd are encrypted at rest, and some platforms intentionally don't even
allow you to interact with etcd directly.

A step up from Kubernetes Secrets, which potentially entails quite a bit
more infrastructure and cognitive/technical burden, would be to use
something like [Vault](https://www.vaultproject.io/) that provides more robust secrets management. There
are open-source tools available for managing a Vault cluster on top of
Kubernetes, including an [Operator](https://github.com/coreos/vault-operator) that configures Vault to use etcd for
its internal storage instead of [Consul](https://www.consul.io/).

In the sample below, each entry within `data` represents an environment
variable, while its value is a base64-encoded form of the raw string like
we used with `docker-compose.yml`. In each case, it's generally important
to ensure that no wayward newlines wind up as part of the encoded value,
because tools like Ecto won't appreciate trying to parse that. As with the
ConfigMap above, these correspond with keys we provided in the
`docker-compose.yml`'s `environment` section.

Among other techniques, you can encode a value for use in a Secret by
using `echo -n` and piping it to `base64`, and you can decode it by piping
the encoded string to `base64 -D` instead. Note that these commands are
very likely to be persisted into your local shell history. Anyone with
access to your shell and a bit of knowledge could read them back out.
Right now that doesn't matter because they'd only be able to compromise
our Minikube environment, but this is still a drawback to be aware of.
Check the appendix for [some references](#preventing-shell-history) around preventing this information
from entering your shell history. Several text editors, Emacs in
particular, have direct support for base64 encoding and decoding strings
in-line.

{{< highlight yaml "linenos=table, linenostart=1" >}}
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: kube-native-env-secret
  labels:
    app: kube-native
    data:
      # echo -n "string" | base64
      # ecto://kube_native:kube_native@kube-native-postgresql.kube-native.svc.cluster.local/kube_native
      DATABASE_URL: ZWN0bzovL2t1YmVfbmF0aXZlOmt1YmVfbmF0aXZlQGt1YmUtbmF0aXZlLXBvc3RncmVzcWwua3ViZS1uYXRpdmUuc3ZjLmNsdXN0ZXIubG9jYWwva3ViZV9uYXRpdmU=
      # "cookie"
      ERLANG_COOKIE: Y29va2ll
      # value from docker-compose.yml, base64-encoded
      SECRET_KEY_BASE: ZnpCazhPRWNJOHRoR3hseXBXUFVxZlIydzJXb3BkTjh2OHBtcHV5MkpOajJlZXJiWUZubGVjdVZNckZQR1luVw==
{{< /highlight >}}

The first substantial change from our `docker-compose.yml` content is to
make sure that we're referring to the new PostgreSQL Service we
provisioned via Helm above, by using its DNS hostname.

The default domain suffix on every Kubernetes cluster is
`svc.cluster.local`, so referring to any Service via DNS takes the
following form:

`service-name.namespace.svc.cluster.local`

For our PostgreSQL service, that gives us:

`kube-native-postgresql.kube-native.svc.cluster.local`

You can verify that you have the right Service name with:

```shell
kubectl get svc -n kube-native
```

Among the output of the above is the service's ClusterIP, which should
directly match how the DNS name resolves inside your container, unless
you've customized a Pod's `dnsConfig` or `dnsPolicy` via its `spec`.

Once again, we install this Secret with `kubectl apply`:

```shell
kubectl apply -n kube-native -f secret.yaml
```

There are also several variations of `kubectl create secret` that would
allow you to supply raw values and it will base64-encode them for you, but
this is less conducive to iterative updates. I find that approach the most
helpful when dealing with pre-existing TLS certificates and keys, as we'll
see later in the series.


### Deployment {#deployment}

Now that the necessary configuration data has been written, we need to
define the actual behavior of the running container. This is noticeably
more verbose than a comparable `docker-compose.yml` service, but every
piece has its purpose, and much of it represents functionality that
Docker Compose does not provide.

The complete file:

{{< highlight yaml "linenos=table, linenostart=1" >}}
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: kube-native
  labels:
    app: kube-native
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: kube-native
  strategy:
    rollingUpdate:
      maxSurge: 10%
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: kube-native
    spec:
      containers:
        - name: kube-native
          image: kube-native:latest
          imagePullPolicy: Never # Always, IfNotPresent, Never
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          envFrom:
            - configMapRef:
                name: kube-native-env
            - secretRef:
                name: kube-native-env-secret
          ports:
            - name: http
              containerPort: 4000
              protocol: TCP
          livenessProbe:
            exec:
              command:
                - /app/bin/kube_native_umbrella
                - ping
            initialDelaySeconds: 5
            periodSeconds: 30
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 5
          resources:
            limits:
              cpu: 1000m
              memory: 256Mi
            requests:
              cpu: 250m
              memory: 128Mi
{{< /highlight >}}

We'll work our way through the highlights of this content, little by
little. Much of the prose description will describe fields using a
dot-separated notation, such as `spec.template.metadata`, which matches
the syntax you can use with the **incredibly handy** `kubectl explain`
command to see more detail about that portion of the manifest schema.

> Please forgive the lack of proper indentation on each smaller snippet - I
> don't appear to have enough control with Hugo to force indentation without
> introducing extra content that wasn't really there in the complete example.

This first section of the `spec` describes "meta" behavior around the
Deployment and how it manages its underlying ReplicaSets. Specifically, it
caps the historical limit to 10 unique iterations, and asserts that
rolling updates must be performed in an **additive** way. Rather than taking
down old Pods and replacing them with new ones, in that order, it instead
will launch new Pods running any updated image or behavior, wait for them
to validate as healthy, and _then_ remove an equivalent number of old
Pods. As written, it allows up to 10% of your stable target capacity to be
duplicated with newer Pods during the upgrade process, and when a
successful deploy is complete, you should be back at your target number of
replicas.

For `spec.selector`, make sure that you have **just enough** labels to
uniquely identify your workload compared to any of its siblings from the
same Kubernetes namespace, without being too precise. In particular, omit
any labels that you might change with each iterative deployment of your
application, such as a version number. If you include such details, you
are running the risk of creating "orphaned" ReplicaSets that don't get
properly reaped or managed by the Deployment object.

{{< highlight yaml "linenos=table, linenostart=7, hl_lines=3 7-11" >}}
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: kube-native
  strategy:
    rollingUpdate:
      maxSurge: 10%
      maxUnavailable: 0
    type: RollingUpdate
{{< /highlight >}}

The `spec.template.metadata.labels` should be either an exact match or
superset of the `spec.selector.matchLabels` above. It's fine to include
additional labels as well. Some sorts of information belong in
`annotations` instead. One useful heuristic is the following question: **Do
I need to query and filter my Pods by this property?** If the answer is
yes, the information probably belongs in a label, if no, it probably
belongs in an annotation.

Note that just about any property within the `spec.template` that gets
changed will trigger a rollout of new Pods, so be mindful of what
information you include. Volatile details like a CI/CD build number may
cause unnecessary churn of your running Pods when their configuration has
not changed in other, more semantically meaningful ways.

`spec.template.spec.containers.image` and `.imagePullPolicy` are how we
dictate which image should be running within the Pod. I've included a
traditionally-reviled practice in this snippet, which is using the
`latest` tag on my Docker image. There are almost no circumstances where
you actually want to use this `latest` tag for serious work, however
expedient it may be. A more sustainable approach is to tag your images
semantically - perhaps with version numbers for your project, a time or
date stamp, a git SHA, or even some combination of the proceeding
identifiers. This lets you reason very specifically about what iteration
of your application is currently running or meant to be running, without
using information that you can only obtain after building the image, such
as its built-in SHA256 digest.

Because we're using a Minikube-based environment in this phase, I've also
set the `imagePullPolicy` to a value of `Never`, because there's nowhere
for the VM to obtain this image if it's not already built locally. In a
live cluster with a remote Docker image registry, we'd generally use one
of `IfNotPresent`, if we're treating image tags as immutable, or `Always`,
if we treat some or all image tags as mutable.

{{< highlight yaml "linenos=table, linenostart=18, hl_lines=8-9" >}}
template:
  metadata:
    labels:
      app: kube-native
  spec:
    containers:
      - name: kube-native
        image: kube-native:latest
        imagePullPolicy: Never # Always, IfNotPresent, Never
{{< /highlight >}}

Within `spec.template.spec.containers.env` we're using the [Downward API](https://kubernetes.io/docs/tasks/inject-data-application/environment-variable-expose-pod-information/) to
expose the Pod's own IP address as an environment variable, which will be
consumed by our Distillery-managed configuration to set the BEAM node name.

We're also using `.envFrom` to source environment variables directly from
our ConfigMap and Secret above.

{{< highlight yaml "linenos=table, linenostart=27" >}}
env:
  - name: POD_IP
    valueFrom:
      fieldRef:
        fieldPath: status.podIP
envFrom:
  - configMapRef:
      name: kube-native-env
  - secretRef:
      name: kube-native-env-secret
{{< /highlight >}}

In order to actually serve traffic from our Pod, we need to expose our HTTP
listener port `4000` to the private network. We give each port a `name` so
that we can refer to it later in the Service declaration, without needing
to remember to update both places if and when a port number changes. Port
names have to be viable for use with DNS notation, so there are some
restrictions on what non-alphanumeric characters can be included.

Notice that we're not making any mention of any of the ports that are
necessary for Distributed Erlang, EPMD, etc. This is intentional! We'll see
later in the series that clustering and distribution don't need those ports
to be formally exposed, because we have a fully routable private network
space to communicate within. This is somewhat unique compared to other
platforms, such as Amazon ECS.

If you have sudden doubts about the security posture of this private
networking model, you'll want to brush up on the [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) resource
type, which requires a supported CNI driver for enforcement. Many
Kubernetes providers support this out of the box or with opt-in
configuration. At the time of writing, GKE uses [Calico](https://www.projectcalico.org/) and an opt-in flag
at cluster creation time, which can also be enabled for existing clusters.

{{< highlight yaml "linenos=table, linenostart=37" >}}
ports:
  - name: http
    containerPort: 4000
    protocol: TCP
{{< /highlight >}}

One of the ways that Kubernetes can help us manage our application's
availability is by continually performing regular health-checking tasks on
our behalf, and responding appropriately to indications of bad container
health.

The YAML below describes two classes of Probes. Failures of a **readiness
probe** will remove the Pod for consideration by Service network traffic,
while a sufficient number of failures of a **liveness probe** will cause
Kubernetes to **restart the container**. A good heuristic to follow is that
readiness probes should fail in circumstances that are possible to
self-heal from without restarting your application, while a liveness probe
should represent a very real failure that can't be resolved with patience
or internal behavior.

Note also that these automatic restarts from liveness probes will contribue
to `CrashLoopBackOff` conditions, and a poorly-tuned or misconfigured probe
may inadvertantly cause more availability problems than they solve.

Our `readinessProbe` currently issues a GET request directly to the root
URL of our Phoenix application. This is a somewhat useful litmus test, but
be wary if the query footprint or other performance characteristics of that
root URL start to grow - these probes are tunable but by default those
requests happen **every 10 seconds, per-Pod**. If the homepage gets to be too
heavy, it's common to create a specific Plug endpoint just for
health-checking purposes, but ideally that endpoint should perform a quick
round-trip to the database to ensure correct credentials.

The `livenessProbe` uses a facility built into the Distillery-provided CLI
to `ping` our BEAM process and wait for a response. If the BEAM is in a
truly bad state this will fail as intended, but under heavy workloads it
potentially can exceed the default timeout of 1 second to come back.

{{< highlight yaml "linenos=table, linenostart=41" >}}
livenessProbe:
  exec:
    command:
      - /app/bin/kube_native_umbrella
      - ping
  initialDelaySeconds: 5
  periodSeconds: 30
  timeoutSeconds: 5
readinessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 5
{{< /highlight >}}

Finally, we can help maintain the quality-of-service within the overall
cluster by describing the resources that need to be allocated on a per-Pod
basis. The cluster's scheduler uses this information to determine which
Pods, how many Pods, and so on that each available Node can execute without
becoming overloaded. If you provide matching values for both `limits` and
`requests`, your pod is treated as having a guaranteed quality of service,
while any mismatch between the two allows for "bursting" behavior but a
less stringent QOS. Take a look at the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/) for more
details.

These specific numbers are both arbitrary and generous for the content of
the example application. The units are expressed in "millicores" for CPU,
where 1000 represents one full second of one full CPU core, and
[mebibytes/gibibytes/etc](https://en.wikipedia.org/wiki/Mebibyte). for memory. Ideally, you should perform empirical
measurements against an un-constrained version of your application in a
live cluster with meaningful traffic to determine more appropriate values
for your use-case.

Later in the series we'll discuss how to do this with a tool called
Prometheus, which is very popular to use in conjunction with Kubernetes. It
would also be a fairly reasonable starting point to base these figures on
your observed metrics from Erlang's Observer, provided you're running on a
similar OS with the right `MIX_ENV` and representative samples of traffic.
It's even possible to perform Pod-level autoscaling based on these metrics,
which is a very exciting opportunity and can be much more meaningful than
pure CPU/Memory utilization figures.

In practical terms it's not really possible to exceed the supplied CPU
limits due to how they're applied via `cgroups`, but you may find the
application becomes "starved" or unable to sustain the expected throughput.
Your main options there are to allocate more CPU and/or memory per-Pod, or
perhaps more readily available, to just run more Pod replicas to distribute
the traffic evenly across a larger pool of application Pods. If you'd like
to see the specifics of how CPU shares are enforced, take a look at the
[Docker documentation](https://docs.docker.com/config/containers/resource%5Fconstraints/#cpu).

Memory is a slightly more nuanced constraint that is [documented on Docker's
site](https://docs.docker.com/config/containers/resource%5Fconstraints/#limit-a-containers-access-to-memory), where Kubernetes is applying the `--memory` flag for you based on the
Pod's resource allocation. One thing to note if the `limit` and `request`
differ is that your Pod can attempt and sometimes even succeed at
allocating more memory than the `request` value, and will be allowed to
continue using it for as long as it does not exceed the `limit`, and for as
long as there aren't low-memory conditions on the Node's host OS.

{{< highlight yaml "linenos=table, linenostart=54" >}}
resources:
  limits:
    cpu: 1000m
    memory: 256Mi
  requests:
    cpu: 250m
    memory: 128Mi
{{< /highlight >}}

We can start a running Pod on our cluster using `kubectl`, and tweak its
replica count on the fly without using `kubectl edit` or `kubectl apply`
again later, including scaling the Deployment to `0` replicas if that's an
appropriate move.

```shell
kubectl apply -n kube-native -f deployment.yaml
kubectl scale deployment -n kube-native kube-native --replicas=3
```


### Service {#service}

Now that we have running containers, we want to distribute incoming
traffic across the ready replicas equally. For that we'll create a
Service, which targets a similar `selector` as the Deployment used, and
exposes a **Service** port that forwards traffic to the **Pod** port. The
exposed port on the service does not have to match the Pod's port in
number, but every Service port must target an existing port name or number
on the Pod.

In Minikube, we must use ClusterIP or NodePort services as it doesn't have
any facilities for managing an external LoadBalancer. ClusterIP would only
allow traffic from other Pods, so we'll go with NodePort, which will
expose a high-numbered port on the Minikube VM itself for external traffic.

{{< highlight yaml "linenos=table, linenostart=1" >}}
apiVersion: v1
kind: Service
metadata:
  name: kube-native
  labels:
    app: kube-native
spec:
  type: NodePort # LoadBalancer, NodePort, ClusterIP
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app: kube-native
{{< /highlight >}}

Our trusty `kubectl apply` comes to our rescue again:

```shell
kubectl apply -n kube-native -f service.yaml
```


## Running Migrations {#running-migrations}

With our application running, we still need to perform our database
migrations. There are two techniques that are readily available to us for
this purpose, with different trade-offs.

You'll recall that we created our `ReleaseTasks` module and the associated
Distillery custom commands in [Part 2](/blog/2018/11/13/kubernetes-native-phoenix-apps-part-2/#running-migrations-and-seeds), so now we need to trigger that
behavior in a Kubernetes Pod context instead.


### Running migrations/seeds via `kubectl exec` {#running-migrations-seeds-via-kubectl-exec}

The first and simplest technique is to simply connect to a running
application Pod via `kubectl exec`, and trigger our migrations via the
Distillery-provided CLI:

```shell
kubectl get pods -o wide -n kube-native
kubectl exec -it $pod_name sh
bin/kube_native_umbrella migrate
bin/kube_native_umbrella seed
```

This isn't super sustainable and can be quite error-prone, and if our
application fails to boot successfully without its migrations, we'd be
unable to use this approach without resolving that first, which may be a
chicken-and-egg problem. The next section introduces a more complex but
more satisfactory approach.


### Running migrations/seeds via Jobs {#running-migrations-seeds-via-jobs}

A preferable method to perform our migrations is to create a Job object
that executes the same Docker image as our deployment, but uses its
`migrate` or `seed` subcommand and doesn't expose any ports. A sample
appears below, with highlights on the meaningfully different lines. In
most ways, this directly resembles the Deployment template above, adjusted
for the schema for a Job object and omitting the ports list and probes.
All we care about here is whether our command eventually exits 0.

Note that the Job name should be unique per-namespace, or else you'll need
to delete and recreate the resource to run another round of migrations,
which is tedious if not actually problematic. We'll see a convenient way
to automate this as part of the next post in the series, covering Helm.

{{< highlight yaml "linenos=table, linenostart=1, hl_lines=13 18" >}}
apiVersion: batch/v1
kind: Job
metadata:
  name: kube-native-migration-0
  labels:
    app: kube-native
spec:
  template:
    metadata:
      labels:
        app: kube-native
    spec:
      restartPolicy: OnFailure
      containers:
        - name: kube-native
          image: kube-native:latest
          imagePullPolicy: IfNotPresent
          args: ["migrate"]
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          envFrom:
            - configMapRef:
                name: kube-native-env
            - secretRef:
                name: kube-native-env-secret
          resources:
            limits:
              cpu: 1000m
              memory: 256Mi
            requests:
              cpu: 250m
              memory: 128Mi
{{< /highlight >}}

Once last time, we create the Job resource with `kubectl apply`:

```shell
kubectl apply -n kube-native -f job.yaml
```


## Browsing the live application {#browsing-the-live-application}

With our migrations applied and the Service has ready Endpoints, you can
visit the application in your browser with a single command, or just echo
the appropriate URL in your shell for later reference:

```shell
minikube service -n kube-native kube-native
minikube service -n kube-native kube-native --url
```


## Code Checkpoint {#code-checkpoint}

The work presented in this post is reflected in git tag `part-3-end`
available [here](https://github.com/shanesveller/kube-native-phoenix/tree/part-3-end). You can compare these changes to the previous post [here](https://github.com/shanesveller/kube-native-phoenix/compare/part-3-start...part-3-end).


## Acknowledgements {#acknowledgements}

Thanks to early readers Eric Oestrich, Dan Lindeman, and Justin Nauman for
their feedback. Any remaining flaws are my own.


## Appendix {#appendix}


### Software/Tool Versions {#software-tool-versions}

| Software   | Version    |
|------------|------------|
| Distillery | 2.0.12     |
| Docker     | 18.06.1-ce |
| Ecto       | 3.0.1      |
| Elixir     | 1.7.4      |
| Erlang     | 21.1.1     |
| Helm       | 2.11.0     |
| Minikube   | 0.30.0     |
| Phoenix    | 1.4.0      |
| PostgreSQL | 10.5       |


### Preferred Minikube config {#preferred-minikube-config}

```shell
minikube config set bootstrapper kubeadm
minikube config set kubernetes-version v1.11.2
minikube config set cpus 4
minikube config set memory 8192
minikube config set vm-driver hyperkit
minikube config set v 4
minikube config set WantReportErrorPrompt false
```


### Preventing Shell History {#preventing-shell-history}

One technique to avoid this is to prefix the command with a space, which
instructs appropriately-configured shells to omit the following command
from persisted history.

Bash users should take a look at the documentation around [history
facilities](https://www.gnu.org/software/bash/manual/html%5Fnode/Bash-History-Facilities.html), paying close attention to environment variables such as
`HISTFILE`, `HISTIGNORE` and `HISTCONTROL`.

ZSH users similarly can look at [their own documentation](http://zsh.sourceforge.net/Doc/Release/Options.html#History), such as the
variable `HIST_IGNORE_SPACE`.

Fish users like myself can be smug about this behavior being built in.
