#!/bin/bash -x

# containerd conf
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# load modules
modprobe overlay
modprobe br_netfilter

# kuber system conf
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# containerd
apt-get update && sudo apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
systemctl restart containerd

# swapoff
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# kuber repo
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet=1.22.0-00 kubeadm=1.22.0-00 kubectl=1.22.0-00
apt-mark hold kubelet kubeadm kubectl

# kube init
kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.22.0
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# calico net add-on
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo '=======For worker nodes to join'
kubeadm token create --print-join-command
