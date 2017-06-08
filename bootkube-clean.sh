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
# Cleaning up nodes is simple:
### Declare colors to use during the running of this script:
declare -r GREEN="\033[0;32m"

function echo_green {
  echo -e "${GREEN}$1"; tput sgr0
}

source .bootkube_env
printf "Removing bootkube environment from system..."
{ sudo systemctl stop kubelet.service
  sudo docker stop $(sudo docker ps -a | grep k8s| cut -c1-20 | xargs sudo docker stop)
  sudo docker rm -f $(sudo docker ps -a | grep k8s| cut -c1-20 | xargs sudo docker stop)
  sudo rm -rf /etc/kubernetes/
  sudo rm -rf /var/etcd
  sudo rm -rf /var/run/calico
  sudo rm -rf /var/run/flannel
  sudo rm -rf /var/run/kubernetes/*
  sudo rm -rf /var/lib/kubelet/*
  sudo rm -rf /var/run/lock/kubelet.lock
  sudo rm -rf /var/run/lock/api-server.lock
  sudo rm -rf /var/run/lock/etcd.lock
  sudo rm -rf /var/run/lock/pod-checkpointer.lock
### These can optionally be enabled, but a menu is soon to come to clean up the following binaries:
#  sudo rm -rf /usr/local/bin/bootkube
#  sudo rm -rf /usr/local/bin/kubectl
#  sudo rm -rf /usr/local/bin/helm
#  sudo rm -rf /opt/cni
  sudo rm -rf $BOOTKUBE_DIR/bootkube-ci/log/cluster-info*
  sudo rm -rf $BOOTKUBE_DIR/.bootkube
  sudo ip link set flannel.1 down
#  sudo rm -rf /etc/resolv.conf
  sudo hostess del $KUBE_DNS_API $KUBE_IP
  sudo hostess del kubernetes $KUBE_IP
  sudo cp $BOOTKUBE_DIR/bootkube-ci/backups/resolv.conf /etc/resolv.conf
} &> /dev/null

echo_green "\nCOMPLETE!\n"
