#!/bin/bash

source .bootkube_env
printf "\nStarting up Kubernetes Cluster"

sudo systemctl daemon-reload
sudo systemctl restart kubelet.service
nohup sudo bash -c 'bootkube start --asset-dir='$BOOTKUBE_DIR'/.bootkube' >$BOOTKUBE_DIR/bootkube-ci/log/bootkube-start.log 2>&1 &

sudo hostess add $KUBE_DNS_API $KUBE_IP
sudo hostess add kubernetes $KUBE_IP

### WAIT FOR KUBERNETES ENVIRONMENT TO COME UP:
echo -e -n "\nWaiting for master components to start..."
while true; do
  running_count=$(sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig get pods -n kube-system --no-headers 2>/dev/null | grep "Running" | grep "boot" | wc -l)
  ### Expect 4 bootstrap components for a truly "Running" state: etcd, apiserver, controller, and scheduler:
  if [ "$running_count" -ge 4 ]; then
    break
  fi
  echo -n "."
  sleep 1
done
printf "\nSUCCESS"
printf  "\nCluster created!"

sleep 10

printf "\nDeploy requested SDN along with additional labels:"
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig label node --all node-role.kubernetes.io/$KUBE_SDN-node=true --overwrite
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig label node --all node-role.kubernetes.io/master="" --overwrite
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig apply -f $BOOTKUBE_DIR/bootkube-ci/deploy-sdn/$KUBE_SDN

echo -e -n "\nWaiting for all services to be in a running state...\n"
while true; do
  creating_count=$(sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig get pods -n kube-system --no-headers 2>/dev/null | egrep "i(Pending|ContainerCreating)" | grep "kube" | wc -l)
  ### Expect all components to be out of a "Pending" state before collecting log data (this includes CrashLoopBackOff states):
  if [ "$creating_count" -eq 0 ]; then
    break
  fi
  echo -n "."
  sleep 1
done

printf "\n"
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig cluster-info

printf "\nComplete!"
