#!/bin/bash -x

# include br_netfilter module
modprobe br_netfilter

# allow K8s to manipulate iptables
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

# exclude RAM swap
# best practices to avoid false RAM stats
swapoff -a

# docker GPG keys
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/docker-archive-keyring.gpg

# add docker repo
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# install docker
sudo apt-get update; sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# install kubectl via apt-get
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt-get install -y kubeadm kubelet kubectl
apt-mark hold kubeadm kubelet kubectl
systemctl enable kubelet

# network cidr init
kubeadm init --pod-network-cidr=10.244.0.0/16
