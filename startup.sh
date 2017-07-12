#! /bin/bash

sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF > kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo mv kubernetes.list /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y apt-transport-https
sudo apt-get install -y docker.io
sudo apt-get install -y kubelet kubeadm 

sudo systemctl enable docker.service

EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

sudo kubeadm init \
  --apiserver-cert-extra-sans ${EXTERNAL_IP} \
  --kubernetes-version stable-1.7

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/master-

kubectl apply -f \
  http://docs.projectcalico.org/v2.3/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml
