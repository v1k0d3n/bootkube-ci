#!/bin/bash
#!/bin/bash
# BootKube Deployment (FINAL):

## NEW INSTALLATIONS:
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y docker.io vim ethtool traceroute git build-essential lldpd socat

### PREPARE THE ENVIRONMENT:
export CNI_VERSION=v0.5.2                   ### CNI VERSION                 ###
export HELM_VERSION=v2.3.1                  ### HELM VERSION                ###
export BOOTKUBE_VERSION=v0.4.1              ### BOOTKUBE VERSION            ###
export KUBERNETES_VERSION=v1.6.2            ### KUBERNETES VERSION          ###
export KUBE_SDN='calico'                    ### SDN SELECTION               ###
export KUBE_POD_CIDR='10.25.0.0/16'         ### SDN POD CIDR RANGE          ###
export KUBE_SVC_CIDR='10.96.0.0/16'         ### SDN SERVICE CIDR RANGE      ###
export KUBE_HW='ens3'                       ### MODIFY FOR YOUR ENVIRONMENT ###
export KUBE_DNS_API='kubernetes.default'    ### DNS API ENDPOINT            ###
export NSERVER01='10.96.0.10'               ### MODIFY FOR CEPH PVC         ###
export NSERVER02='192.168.1.70'             ### MODIFY FOR YOUR ENVIRONMENT ###
export NSERVER03='8.8.8.8'                  ### MODIFY FOR YOUR ENVIRONMENT ###
export NSEARCH01='svc.cluster.local'        ### MODIFY FOR YOUR ENVIRONMENT ###
export NSEARCH02='jinkit.com'               ### MODIFY FOR YOUR ENVIRONMENT ###
export KUBE_IMAGE='v1k0d3n/hyperkube-amd64' ### MODIFY FOR YOUR ENVIRONMENT ###
export KUBE_IP=$(ip a s dev $KUBE_HW | awk '/inet /{gsub("/.*", "");print $2}')
echo "Kubernetes Endpoint: $KUBE_IP"

### PREPARE: /etc/resolv.conf
sudo -E bash -c "cat <<EOF > /etc/resolv.conf
nameserver $NSERVER01
nameserver $NSERVER02
nameserver $NSERVER03
search $NSEARCH01 $NSEARCH02
EOF"

### PREPARE: /etc/hosts:
sudo -E bash -c 'echo '$KUBE_IP' '$HOSTNAME' '$HOSTNAME'.'$NSEARCH02' '$KUBE_DNS_API' kubernetes >> /etc/hosts'

### PREPARE: /etc/systemd/system/kubelet.service
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
wget https://github.com/kubernetes-incubator/bootkube/releases/download/$BOOTKUBE_VERSION/bootkube.tar.gz
tar zxvf bootkube.tar.gz
sudo chmod +x bin/linux/bootkube
sudo cp bin/linux/bootkube /usr/local/bin/
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
sudo rm -rf /home/$USER/cni-amd64-$CNI_VERSION.tgz
sudo rm -rf /home/$USER/bootkube.tar.gz
sudo rm -rf /home/$USER/bin


### RENDER ASSETS:
sudo /usr/bin/docker run -v /home/ubuntu:/home/ubuntu quay.io/coreos/bootkube:$BOOTKUBE_VERSION /bootkube render --asset-dir=/home/ubuntu/.bootkube --experimental-self-hosted-etcd --etcd-servers=http://10.3.0.15:12379 --api-servers=https://$KUBE_DNS_API:443 --pod-cidr=$KUBE_POD_CIDR --service-cidr=$KUBE_SVC_CIDR
sudo rm -rf /home/ubuntu/.bootkube/manifests/kube-flannel*

### REQUIRED FOR CEPH/OPTIONAL ALL OTHERS:
# sudo grep -rl "quay.io/coreos/hyperkube:$KUBERNETES_VERSION_coreos.0" /home/$USER/.bootkube/ | sudo xargs sed -i 's|quay.io/coreos/hyperkube:$KUBERNETES_VERSION_coreos.0|$KUBE_IMAGE:$KUBERNETES_VERSION|g'
sudo grep -rl quay.io/coreos/hyperkube:$KUBERNETES_VERSION'_coreos.0' /home/$USER/.bootkube/ | sudo xargs sed -i "s|quay.io/coreos/hyperkube:"$KUBERNETES_VERSION"_coreos.0|quay.io/"$KUBE_IMAGE":"$KUBERNETES_VERSION"|g"

### DEPLOY KUBERNETES SELF-HOSTED CLUSTER:
sudo systemctl daemon-reload
sudo systemctl restart kubelet.service
sudo cp /home/ubuntu/.bootkube/auth/kubeconfig /etc/kubernetes/
sudo cp -a /home/$USER/.bootkube/* /etc/kubernetes/
sudo mkdir -p /home/$USER/.kube
sudo cp /etc/kubernetes/kubeconfig /home/$USER/.kube/config
sudo chmod 644 /home/ubuntu/.kube/config
# DEBUG #sudo touch /home/ubuntu/.bootkube/bootkube-up.log
nohup sudo bash -c 'bootkube start --asset-dir=/home/ubuntu/.bootkube &>/dev/null &'

### WAIT FOR KUBERNETES ENVIRONMENT TO COME UP:
declare -r GREEN="\033[0;32m"

function echo_green {
  echo -e "${GREEN}$1"; tput sgr0
}

echo -e -n "Waiting for master components to start..."
while true; do
  running_count=$(sudo kubectl get pods -n kube-system --no-headers 2>/dev/null | grep "Running" | wc -l)
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
sudo kubectl cluster-info

sleep 10

### WAIT FOR KUBERNETES API TO COME UP CLEANLY, THEN APPLY FOLLOWING LABELS AND MANIFESTS:
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig label node --all node-role.kubernetes.io/$KUBE_SDN-node=true --overwrite
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig label node --all node-role.kubernetes.io/master="" --overwrite
sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig apply -f ./deploy-sdn/$KUBE_SDN

printf "\nCOMPLETE!\n"
