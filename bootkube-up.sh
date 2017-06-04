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


### PREPARE THE ENVIRONMENT:
source .bootkube_env
echo_green "\nPhase II: Using the following variables during the deployment:"
printf "BOOTKUBE_DIR: $BOOTKUBE_DIR
CNI_VERSION: $CNI_VERSION
HELM_VERSION: $HELM_VERSION
BOOTKUBE_VERSION: $BOOTKUBE_VERSION
KUBERNETES_VERSION: $KUBERNETES_VERSION
KUBE_SDN: $KUBE_SDN
KUBE_POD_CIDR: $KUBE_POD_CIDR
KUBE_SVC_CIDR: $KUBE_SVC_CIDR
KUBE_HW: $KUBE_HW
KUBE_DNS_API: $KUBE_DNS_API
NSERVER01: $NSERVER01
NSERVER02: $NSERVER02
NSERVER03: $NSERVER03
NSEARCH01: $NSEARCH01
NSEARCH02: $NSEARCH02
KUBE_IMAGE: $KUBE_IMAGE
KUBE_IP: $KUBE_IP \n \n"

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
sudo hostess add $KUBE_DNS_API $KUBE_IP
sudo hostess add kubernetes $KUBE_IP

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

### DOWNLOAD: bootkube
echo_green "\nPhase V: Downloading Bootkube required binaries:"
export TMPDIR=/tmp/download
mkdir -p $TMPDIR

### DOWNLOAD: bootkube
if [[ ! -e '$TMPDIR'/'$BOOTKUBE_VERSION'-bootkube.tgz && ! -e /usr/local/bin/bootkube ]]; then
    wget -O $TMPDIR/$BOOTKUBE_VERSION-bootkube.tgz https://github.com/kubernetes-incubator/bootkube/releases/download/$BOOTKUBE_VERSION/bootkube.tar.gz
    tar zxvf $TMPDIR/$BOOTKUBE_VERSION-bootkube.tgz -C $TMPDIR/
    mv $TMPDIR/bin/ $TMPDIR/$BOOTKUBE_VERSION-bootkube-amd64
    chmod +x $TMPDIR/$BOOTKUBE_VERSION-bootkube-amd64/linux/bootkube
    sudo cp $TMPDIR/$BOOTKUBE_VERSION-bootkube-amd64/linux/bootkube /usr/local/bin/
fi

### DOWNLOAD: kubectl
if [[ ! -e '$TMPDIR'/'$KUBERNETES_VERSION'-kubectl-amd64 && ! -e /usr/local/bin/kubectl ]]; then
    wget -O $TMPDIR/$KUBERNETES_VERSION-kubectl-amd64 http://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/kubectl
    chmod +x $TMPDIR/$KUBERNETES_VERSION-kubectl-amd64
    sudo cp $TMPDIR/$KUBERNETES_VERSION-kubectl-amd64 /usr/local/bin/kubectl
fi

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

### DOWNLOAD: helm
if [[ ! -e '$TMPDIR'/'$HELM_VERSION'-helm-amd64.tgz && ! -e /usr/local/bin/helm ]]; then
    wget -O $TMPDIR/$HELM_VERSION-helm-amd64.tgz https://storage.googleapis.com/kubernetes-helm/helm-$HELM_VERSION-linux-amd64.tar.gz
    tar zxvf $TMPDIR/$HELM_VERSION-helm-amd64.tgz -C $TMPDIR/
    mv $TMPDIR/linux-amd64/ $TMPDIR/$HELM_VERSION-helm-amd64
    chmod +x $TMPDIR/$HELM_VERSION-helm-amd64/helm
    sudo cp $TMPDIR/$HELM_VERSION-helm-amd64/helm /usr/local/bin/
fi

### CLEANUP:
cd $BOOTKUBE_DIR
sudo rm -rf $TMPDIR/linux-amd64
echo_green "\nComplete!"

### RENDER ASSETS:
echo_green "\nPhase VI: Running Bootkube to render the Kubernetes assets:"
bootkube render --asset-dir=$BOOTKUBE_DIR/.bootkube --experimental-self-hosted-etcd --etcd-servers=http://10.3.0.15:12379 --api-servers=https://$KUBE_DNS_API:443 --pod-cidr=$KUBE_POD_CIDR --service-cidr=$KUBE_SVC_CIDR
sudo rm -rf $BOOTKUBE_DIR/.bootkube/manifests/kube-flannel*
if [ $KUBE_SDN = "kube-router" ]; then
   echo_yellow "\nSDN variable is set to kube-router. Proceeding to remove kube-proxy manifests for Bootkube!" && sudo rm -rf $BOOTKUBE_DIR/.bootkube/manifests/kube-proxy.yaml
else
   echo_green "\nSDN is set to $KUBE_SDN. No additional changes are required for $KUBE_SDN!"
fi

### REQUIRED FOR CEPH/OPTIONAL ALL OTHERS:
echo_green "\nPhase VII: If requested, modifying the rendered assets to include a custom Hyperkube image:"
sudo grep -rl quay.io/coreos/hyperkube:$KUBERNETES_VERSION'_coreos.0' $BOOTKUBE_DIR/.bootkube/ | sudo xargs sed -i "s|quay.io/coreos/hyperkube:"$KUBERNETES_VERSION"_coreos.0|quay.io/"$KUBE_IMAGE":"$KUBERNETES_VERSION"|g"

### DEPLOY KUBERNETES SELF-HOSTED CLUSTER:
echo_green "\nPhase VIII: Preparing the environment for Kubernetes to run for the first time:"
sudo systemctl daemon-reload
sudo systemctl restart kubelet.service
sudo cp $BOOTKUBE_DIR/.bootkube/auth/kubeconfig /etc/kubernetes/
sudo cp -a $BOOTKUBE_DIR/.bootkube/* /etc/kubernetes/

### Ensuring that kubectl has a proper configuration file in the $USER/.kube directory, and backing up the old config file if required:
if [[ ! -e ~/.kube/config ]]; then
     echo_green "Copying Kubernetes config to $HOME/.kube/config" && sudo mkdir -p ~/.kube && sudo cp /etc/kubernetes/kubeconfig ~/.kube/config
 else
     echo_yellow "Moving old $HOME/.kube/config to $HOME/.kube/config.backup" && sudo cp ~/.kube/config ~/.kube/config.backup && sudo cp /etc/kubernetes/kubeconfig ~/.kube/config
fi
sudo chmod 644 ~/.kube/config


echo_green "\nPhase IX: Running Bootkube start to bring up the temporary Kubernetes self-hosted control plane:"
nohup sudo bash -c 'bootkube start --asset-dir='$BOOTKUBE_DIR'/.bootkube' >$BOOTKUBE_DIR/bootkube-ci/log/bootkube-start.log 2>&1 &

### WAIT FOR KUBERNETES ENVIRONMENT TO COME UP:
echo -e -n "Waiting for master components to start..."
while true; do
  running_count=$(sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig get pods -n kube-system --no-headers 2>/dev/null | grep "Running" | grep "boot" | wc -l)
  ### Expect 4 bootstrap components for a truly "Ready" state: etcd, apiserver, controller, and scheduler:
  if [ "$running_count" -ge 4 ]; then
    break
  fi
  echo -n "."
  sleep 1
done
echo_green "SUCCESS"
echo_green "Cluster created!"
echo ""
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig cluster-info

sleep 10

### WAIT FOR KUBERNETES API TO COME UP CLEANLY, THEN APPLY FOLLOWING LABELS AND MANIFESTS:
echo_green "\nPhase X: Cluster created, and now deploying requested SDN along with additional labels:"
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig label node --all node-role.kubernetes.io/$KUBE_SDN-node=true --overwrite
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig label node --all node-role.kubernetes.io/master="" --overwrite
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig apply -f $BOOTKUBE_DIR/bootkube-ci/deploy-sdn/$KUBE_SDN


echo_green "\nPhase XI: Writing Kubernetes environment cluster-info logs:"
### WAIT FOR KUBERNETES ENVIRONMENT TO COME UP:
echo -e -n "Waiting for all services to be in a running state..."
while true; do
  creating_count=$(sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig get pods -n kube-system --no-headers 2>/dev/null | grep "ContainerCreating" | grep "kube" | wc -l)
  ### Expect all components to be out of a "ContainerCreating" state before collecting log data (this includes CrashLoopBackOff states):
  if [ "$creating_count" -eq 0 ]; then
    break
  fi
  echo -n "."
  sleep 1
done
export CLUSTER_TIMESTAMP="$(date +%s)"
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig cluster-info dump --all-namespaces --output-directory "$BOOTKUBE_DIR/bootkube-ci/log/cluster-info-$CLUSTER_TIMESTAMP"
echo_yellow "\nCluster logs can be found in $BOOTKUBE_DIR/bootkube-ci/log/cluster-info-$CLUSTER_TIMESTAMP"
echo_green "\nCOMPLETE!\n"
