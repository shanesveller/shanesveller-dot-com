+++
title = "Monitoring GKE with CoreOS' Prometheus Operator"
tags = ["coreos", "monitoring", "prometheus", "gke", "kubernetes"]
categories = ["kubernetes"]
weight = 2001
draft = true
+++

## Software/Tool Versions {#software-tool-versions}

| Project             | Version     |
|---------------------|-------------|
| Google Cloud SDK    | 182.0.0     |
| Kubernetes          | 1.8.3-gke.0 |
| Helm                | 2.7.2       |
| Prometheus Operator | 0.15.0      |
| Prometheus          | 1.8.2       |


## Background {#background}

[Prometheus](https://prometheus.io/) is all the rage in the Kubernetes community, especially after
becoming a Cloud Native Computing Foundation [hosted project](https://www.cncf.io/projects/).

CoreOS has a project called [prometheus-operator](https://github.com/coreos/prometheus-operator) which helps manage instances
of a Prometheus server, or its compatriot AlertManager, via Kubernetes manifests.


## Getting Started {#getting-started}

I've chosen to install the Operator via the project's provided [Helm Chart](https://github.com/coreos/prometheus-operator/tree/v0.15.0/helm/prometheus-operator).

First, install CoreOS' Helm repository

```shell-script
helm init --client-only
helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
```

I've also provided some customized values:

```yaml
global:
  ## Hyperkube image to use when getting ThirdPartyResources & cleaning up
  ##
  hyperkube:
    repository: quay.io/coreos/hyperkube
    # https://quay.io/repository/coreos/hyperkube?tag=latest&tab=tags
    tag: v1.8.4_coreos.0
    pullPolicy: IfNotPresent

## Prometheus-operator image
##
image:
  repository: quay.io/coreos/prometheus-operator
  # https://quay.io/repository/coreos/prometheus-operator?tag=latest&tab=tags
  tag: v0.15.0
  pullPolicy: IfNotPresent
```

Finally, I install the chart with my supplied values in a `monitoring` namespace:

```shell-script
helm install --name prometheus-operator \
     --namespace monitoring \
     --values prometheus-operator-values.yaml \
     coreos/prometheus-operator
```


## Using kube-prometheus for basic cluster metrics {#using-kube-prometheus-for-basic-cluster-metrics}

```shell-script
helm install --name kube-prometheus \
     --namespace monitoring \
     --values kube-prometheus-values.yaml \
     coreos/kube-prometheus
```
