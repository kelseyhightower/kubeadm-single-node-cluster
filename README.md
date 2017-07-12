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
  --metadata kubernetes-version=stable-1.7,startup-script-url=https://raw.githubusercontent.com/kelseyhightower/kubeadm-single-node-cluster/master/startup.sh \
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
gcloud compute scp kubeadm-single-node-cluster:/etc/kubernetes/admin.conf \
  kubeadm-single-node-cluster.conf
```

> It may take a few minutes for the cluster to finish bootstrapping and the client config to become readable.

Set the `kubeadm-single-node-cluster` kubeconfig server address to the public IP address:

```
kubectl config set-cluster kubernetes \
  --kubeconfig kubeadm-single-node-cluster.conf \
  --server https://$(gcloud compute instances describe kubeadm-single-node-cluster \
     --format='value(networkInterfaces.accessConfigs[0].natIP)'):6443
```

## Verification

List the Kubernetes nodes:

```
kubectl get nodes --kubeconfig kubeadm-single-node-cluster.conf
```
``` 
NAME                          STATUS    AGE       VERSION
kubeadm-single-node-cluster   Ready     14m       v1.7.0
```

Create a nginx deployment:

```
kubectl run nginx --image nginx:1.13 --port 80 \
  --kubeconfig kubeadm-single-node-cluster.conf
```

Expose the nginx deployment:

```
kubectl expose deployment nginx \
  --type LoadBalancer \
  --kubeconfig kubeadm-single-node-cluster.conf
```

## Cleanup

```
gcloud compute instances delete kubeadm-single-node-cluster
```

```
gcloud compute firewall-rules delete default-allow-kubeadm-single-node-cluster
```

```
rm kubeadm-single-node-cluster.conf
```
