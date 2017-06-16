#!/bin/bash
# Copyright 2017 The Bootkube-CI Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
### Declare colors to use during the running of this script:
declare -r GREEN="\033[0;32m"
declare -r RED="\033[0;31m"
declare -r YELLOW="\033[0;33m"

function echo_green {
  echo -e "${GREEN}$1"; tput sgr0
}
function echo_red {
  echo -e "${RED}$1"; tput sgr0
}
function echo_yellow {
  echo -e "${YELLOW}$1"; tput sgr0
}

source .bootkube_env

## NEW INSTALLATIONS:
echo_green "\nPhase I: Installing system prerequisites:"
pkg="vim curl ethtool traceroute git build-essential lldpd socat"

for pkg in $pkg; do
    if sudo dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$" >/dev/null; then
        echo -e "$pkg is already installed"
    else
        sudo apt-get update && sudo apt-get -qq install $pkg
        echo "Successfully installed $pkg"
    fi
done

if ! which docker > /dev/null; then
   echo -e "Docker is not installed on this host. Installing latest version... \c"
      curl -sSL https://get.docker.com/ | sh
fi

mkdir -p $BOOTKUBE_DIR/bootkube-ci/

### PREPARE: /etc/resolv.conf
echo_green "\nPhase III: Preparing system DNS:"
sudo cp /etc/resolv.conf $BOOTKUBE_DIR/bootkube-ci/backups/

### PREPARE: /etc/resolv.conf
sudo -E bash -c "cat <<EOF > /etc/resolvconf/resolv.conf.d/head
nameserver $NSERVER01
EOF"
sudo -E bash -c "cat <<EOF > /etc/resolvconf/resolv.conf.d/base
search kubernetes $KUBE_DNS_API $NSEARCH01 $NSEARCH02
EOF"
sudo resolvconf -u
echo_yellow "\e[3mBootkube-CI Users: '/etc/resolv.conf is not a symbolic link' warning above is OK!\e[0m"

### PREPARE: /etc/hosts with idempotency (hostess):
### DOWNLOAD: bootkube
if [ ! -e /usr/local/bin/hostess ]; then
    sudo wget -O /usr/local/bin/hostess https://github.com/cbednarski/hostess/releases/download/v0.2.0/hostess_linux_amd64
    sudo chmod +x /usr/local/bin/hostess
fi
sudo hostess add $KUBE_DNS_API $KUBE_MASTER
sudo hostess add kubernetes $KUBE_MASTER

### PREPARE: /etc/systemd/system/kubelet.service
echo_green "\nPhase VI: Deploying the Kubelet systemd unit:"
printf "Kublet deployed to host:\n"
echo_red "[Unit]
Description=Kubernetes Kubelet
Documentation=https://kubernetes.io/docs/admin/kubelet/
[Service]
ExecStartPre=/bin/mkdir -p /etc/kubernetes/manifests
ExecStart=/usr/local/bin/kubelet \\
    --kubeconfig=/etc/kubernetes/kubeconfig \\
    --require-kubeconfig \\
    --cni-conf-dir=/etc/cni/net.d \\
    --cni-bin-dir=/opt/cni/bin \\
    --network-plugin=cni \\
    --lock-file=/var/run/lock/kubelet.lock \\
    --exit-on-lock-contention \\
    --pod-manifest-path=/etc/kubernetes/manifests \\
    --allow-privileged \\
    --cluster_dns='$NSERVER01','$NSERVER02','$NSERVER03' \\
    --cluster_domain=cluster.local \\
    --node-labels= \\
    --hostname-override='$KUBE_IP' \\
    --v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target\n"

sudo -E bash -c 'cat <<EOF > /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://kubernetes.io/docs/admin/kubelet/
[Service]
ExecStartPre=/bin/mkdir -p /etc/kubernetes/manifests
ExecStart=/usr/local/bin/kubelet \\
    --kubeconfig=/etc/kubernetes/kubeconfig \\
    --require-kubeconfig \\
    --cni-conf-dir=/etc/cni/net.d \\
    --cni-bin-dir=/opt/cni/bin \\
    --network-plugin=cni \\
    --lock-file=/var/run/lock/kubelet.lock \\
    --exit-on-lock-contention \\
    --pod-manifest-path=/etc/kubernetes/manifests \\
    --allow-privileged \\
    --cluster_dns='$NSERVER01','$NSERVER02','$NSERVER03' \\
    --cluster_domain=cluster.local \\
    --node-labels= \\
    --hostname-override='$KUBE_IP' \\
    --v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF'

### DOWNLOAD: kubelet
if [[ ! -e '$TMPDIR'/'$KUBERNETES_VERSION'-kubelet-amd64 && ! -e /usr/local/bin/kubelet ]]; then
    wget -O $TMPDIR/$KUBERNETES_VERSION-kubelet-amd64 http://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/kubelet
    chmod +x $TMPDIR/$KUBERNETES_VERSION-kubelet-amd64
    sudo cp $TMPDIR/$KUBERNETES_VERSION-kubelet-amd64 /usr/local/bin/kubelet
fi

### DOWNLOAD: cni
if [[ ! -e '$TMPDIR'/'$CNI_VERSION'-cni-amd64.tgz && ! -e /opt/cni/bin ]]; then
    wget -O $TMPDIR/$CNI_VERSION-cni-amd64.tgz https://github.com/containernetworking/cni/releases/download/$CNI_VERSION/cni-amd64-$CNI_VERSION.tgz
    sudo mkdir -p /opt/cni/bin
    sudo tar -xf $TMPDIR/$CNI_VERSION-cni-amd64.tgz -C /opt/cni/bin/
fi

### DEPLOY KUBERNETES SELF-HOSTED CLUSTER:
echo_green "\nPhase VIII: Preparing the environment for Kubernetes to run for the first time:"
ssh ubuntu@$KUBENODE "sudo systemctl daemon-reload"
ssh ubuntu@$KUBENODE "sudo systemctl restart kubelet.service"
