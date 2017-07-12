# kubeadm: Single Node Kubernetes Cluster

This tutorial will walk you through bootstrapping a single-node Kubernetes cluster on [Google Compute Engine](https://cloud.google.com/compute/) using [kubeadm](https://github.com/kubernetes/kubeadm).

## Tutorial

Create a single compute instance:

```
gcloud compute instances create kubeadm-single-node-cluster \
  --can-ip-forward \
  --image-family ubuntu-1704 \
  --image-project ubuntu-os-cloud \
  --machine-type n1-standard-4 \
  --metadata startup-script-url=https://raw.githubusercontent.com/kelseyhightower/kubeadm-single-node-cluster/master/startup.sh \
  --tags kubeadm-single-node-cluster \
  --scopes cloud-platform,logging-write
```

Enable secure remote access to the Kubernetes API server:

```
gcloud compute firewall-rules create default-allow-kubeadm-single-node-cluster \
  --allow tcp:6443 \
  --target-tags kubeadm-single-node-cluster \
  --source-ranges 0.0.0.0/0
```

Fetch the client kubernetes configuration file:

```
gcloud compute scp kubeadm-single-node-cluster:~/.kube/config kubeadm-single-node-cluster.conf
```
