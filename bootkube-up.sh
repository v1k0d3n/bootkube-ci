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

function echo_green {
  echo -e "${GREEN}$1"; tput sgr0
}
function echo_red {
  echo -e "${RED}$1"; tput sgr0
}


## NEW INSTALLATIONS:
echo_green "\nPhase I: Installing system prerequisites:"
pkg="vim ethtool traceroute git build-essential lldpd socat"

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
sudo sed -i '1s/^/nameserver '$NSERVER01'\n/' /etc/resolv.conf
sudo sed -i '1s/^/search '$KUBE_DNS_API' '$NSEARCH01' '$NSEARCH02'\n/' /etc/resolv.conf

### PREPARE: /etc/hosts with idempotency (hostess):
wget https://github.com/cbednarski/hostess/releases/download/v0.2.0/hostess_linux_amd64
sudo mv hostess_linux_amd64 /usr/local/bin/hostess
sudo chmod +x /usr/local/bin/hostess

#sudo -E bash -c 'echo '$KUBE_IP' '$HOSTNAME' '$HOSTNAME'.'$NSEARCH02' '$KUBE_DNS_API' >> /etc/hosts'
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
    --cluster_dns='$NSERVER02','$NSERVER03','$NSERVER01' \\
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
    --cluster_dns='$NSERVER02','$NSERVER03','$NSERVER01' \\
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

### DOWNLOAD: bootkube
if ! which bootkube > /dev/null; then
   echo -e "Bootkube $BOOTKUBE_VERSION is not installed on this host. Installing version requested... \c"
      wget https://github.com/kubernetes-incubator/bootkube/releases/download/$BOOTKUBE_VERSION/bootkube.tar.gz && \
      tar zxvf bootkube.tar.gz && \
      sudo chmod +x bin/linux/bootkube && \
      sudo cp bin/linux/bootkube /usr/local/bin/
fi

### DOWNLOAD: kubectl
wget http://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/kubectl
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/
### DOWNLOAD: cni
wget https://github.com/containernetworking/cni/releases/download/$CNI_VERSION/cni-amd64-$CNI_VERSION.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -xf cni-amd64-$CNI_VERSION.tgz -C /opt/cni/bin/
### DOWNLOAD: kubelet
wget http://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/kubelet
sudo mv kubelet /usr/local/bin/kubelet
chmod +x /usr/local/bin/kubelet
### DOWNLOAD: helm
wget -O /tmp/helm-$HELM_VERSION-linux-amd64.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-$HELM_VERSION-linux-amd64.tar.gz
tar zxvf /tmp/helm-$HELM_VERSION-linux-amd64.tar.gz -C /tmp/
chmod +x /tmp/linux-amd64/helm
sudo mv /tmp/linux-amd64/helm /usr/local/bin/
sudo rm -rf /tmp/linux-amd64
### CLEANUP:
sudo rm -rf $BOOTKUBE_DIR/cni-amd64-$CNI_VERSION.tgz
sudo rm -rf $BOOTKUBE_DIR/bootkube.tar.gz
sudo rm -rf $BOOTKUBE_DIR/bin


### RENDER ASSETS:
echo_green "\nPhase VI: Running Bootkube to render the Kubernetes assets:"
bootkube render --asset-dir=$BOOTKUBE_DIR/.bootkube --experimental-self-hosted-etcd --etcd-servers=http://10.3.0.15:12379 --api-servers=https://$KUBE_DNS_API:443 --pod-cidr=$KUBE_POD_CIDR --service-cidr=$KUBE_SVC_CIDR
sudo rm -rf $BOOTKUBE_DIR/.bootkube/manifests/kube-flannel*

### REQUIRED FOR CEPH/OPTIONAL ALL OTHERS:
echo_green "\nPhase VII: If requested, modifying the rendered assets to include a custom Hyperkube image:"
sudo grep -rl quay.io/coreos/hyperkube:$KUBERNETES_VERSION'_coreos.0' $BOOTKUBE_DIR/.bootkube/ | sudo xargs sed -i "s|quay.io/coreos/hyperkube:"$KUBERNETES_VERSION"_coreos.0|quay.io/"$KUBE_IMAGE":"$KUBERNETES_VERSION"|g"

### DEPLOY KUBERNETES SELF-HOSTED CLUSTER:
echo_green "\nPhase VIII: Preparing the environment for Kubernetes to run for the first time:"
sudo systemctl daemon-reload
sudo systemctl restart kubelet.service
sudo cp $BOOTKUBE_DIR/.bootkube/auth/kubeconfig /etc/kubernetes/
sudo cp -a $BOOTKUBE_DIR/.bootkube/* /etc/kubernetes/
sudo mkdir -p $BOOTKUBE_DIR/.kube
sudo cp /etc/kubernetes/kubeconfig ~/.kube/config
sudo chmod 644 ~/.kube/config

echo_green "\nPhase IX: Running Bootkube start to bring up the temporary Kubernetes self-hosted control plane:"
nohup sudo bash -c 'bootkube start --asset-dir='$BOOTKUBE_DIR'/.bootkube' &>$BOOTKUBE_DIR/bootkube-ci/log/bootkube-start.log 2>&1 &

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
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig apply -f ./deploy-sdn/$KUBE_SDN


echo_green "\nPhase XI: Writing Kubernetes environment cluster-info dump to $BOOTKUBE_DIR/bootkube-ci/log/cluster-info.log:"
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig cluster-info dump > $BOOTKUBE_DIR/bootkube-ci/log/cluster-info.log
echo_green "\nCOMPLETE!\n"
