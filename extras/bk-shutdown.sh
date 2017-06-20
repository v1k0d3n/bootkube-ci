#!/bin/bash

source .bootkube_env
printf "Shutting down Kubernetes cluster..."
{ sudo systemctl stop kubelet.service
  sudo docker stop $(sudo docker ps -a | grep k8s| cut -c1-20 | xargs sudo docker stop)
  sudo docker rm -f $(sudo docker ps -a | grep k8s| cut -c1-20 | xargs sudo docker stop)
  sudo ip link set flannel.1 down
  sudo hostess del $KUBE_DNS_API $KUBE_IP
  sudo hostess del kubernetes $KUBE_IP
  sudo iptables -F
  sudo iptables -X
} &> /dev/null

printf "\nComplete!\n"
