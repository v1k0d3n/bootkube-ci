Bootkube-CI is a simple Kubernetes environment that can be used for a number of CI, development and/or demonstration scenarios. A primary usecase for this repository is for the demonstration of [OpenStack-Helm](https://github.com/openstack/openstack-helm) delivered on top of a Self-Hosted Kubernetes control plane via [Kubernetes-Incubator/Bootkube](https://github.com/kubernetes-incubator/bootkube).

# Deployment Instructions:

If you wish to use this repository for CI or for bringing up a Kubernetes cluster, simply clone and edit the `.bootkube_env` file to match your environment. Currently, two SDN's are optional and included (Calico is default).

Included with this repository are the concepts of "add-ons": other deployment scenarios that you may want to run after a Kubernetes self-hosted cluster has been deployed. Using these are just as straight-forward as using the deployment itself. So if you wanted to deploy [openstack-helm](https://github.com/openstack/openstack-helm) for example, all that would be required is the following:

```
git clone https://github.com/v1k0d3n/bootkube-ci.git

## make any variable modifications via your CI platform of choice to both .bootkube-env and ./deploy-addons/openstack-helm-up.sh
## and deploy

cd bootkube-ci
./bootkube-up
cd deploy-addons
./openstack-helm-up

# done
```

## Kubernetes Config File
By default, the Bootkube generated Kubernetes configuration will not work with Armada, because the config is not technically valid (Tiller will return an error message). This is because the certificate and key data is `REDACTED`, and because there is no default context configured. In order to create a valid `/home/${USER}/.kube/config` file (for use with [Armada](https://github.com/att-comdev/armada)), you will need to perform the following manual actions:

```
### Move Old Kubernetes Config:
#   Source .bootkube_env file in bootkube-ci folder:
source .bootkube_env
sudo mv ${HOME}/.kube/config ${HOME}/

### Create Valid Kubernetes User Config:
sudo kubectl config set-cluster local --server=https://${KUBE_MASTER}:${KUBE_SVC_PORT} --certificate-authority=${BOOTKUBE_DIR}/.bootkube/tls/ca.crt
sudo kubectl config set-context default --cluster=local --user=kubelet
sudo kubectl config use-context default
sudo kubectl config set-credentials kubelet --client-certificate=${BOOTKUBE_DIR}/.bootkube/tls/kubelet.crt  --client-key=${BOOTKUBE_DIR}/.bootkube/tls/kubelet.key
sudo chown -R ${USER} ${HOME}/.kube
```

Now you should be able to use your cluster with Armada.

## Creating Client Certificates

Currently, this project uses the `kubelet` user for communicating with the cluster. In production environments, this is unacceptable. You will want to consider creating authenticated client certificates so your users can communicate with the cluster with valid certificates and [RBAC](https://kubernetes.io/docs/admin/authorization/rbac/) policies. To create client certificates, perform the following additional tasks (we will make this default behavior soon):

```
### EXPORT ORG NAME/EXPIRATION IN DAYS:
export ORGANIZATION=charter
export CERT_EXPIRATION=730

### DIRECTORY PREPARATION:
mkdir -f ~/.kube_certs
mv ~/.kube/config ~/.kube/backup_kubeconfig
rm -rf ${HOME}/.kube_certs/*

### CERTIFICATE CREATION FOR END USERS:
openssl genrsa -out ~/.kube_certs/${USER}.key 2048
openssl req -new -key ~/.kube_certs/${USER}.key -out ~/.kube_certs/${USER}.csr -subj "/CN=${USER}/O=${ORGANIZATION}"
openssl x509 -req -in ~/.kube_certs/${USER}.csr -CA ~/.bootkube/tls/ca.crt -CAkey ~/.bootkube/tls/ca.key -CAcreateserial -out ~/.kube_certs/${USER}.crt -days ${CERT_EXPIRATION}
```

## Resizing Etcd Cluster:

Bootkube leverages an [Etcd Operator](https://github.com/coreos/etcd-operator) provided by CoreOS. This means that Etcd can be dynamically scaled and various maintenance functions can be performed as well. To scale your Etcd cluster, you'll want to adjust the `size` definition located within the `spec` section of the deployed [Custom Resource (CRD)](https://kubernetes.io/docs/concepts/api-extension/custom-resources/). To obtain the CRD, export it and modify the size to the desired number of Etcd members.

```
# export the crd:
kubectl get EtcdCluster -n kube-system -o yaml > ${HOME}/bootkube-ci/etcd-cluster-resize.yaml

# example spec section below:
  spec:
    TLS:
      static:
        member:
          peerSecret: etcd-peer-tls
          serverSecret: etcd-server-tls
        operatorSecret: etcd-client-tls
    baseImage: quay.io/coreos/etcd
    pod:
      nodeSelector:
        node-role.kubernetes.io/master: ""
      resources: {}
      tolerations:
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
        operator: Exists
    selfHosted:
      bootMemberClientEndpoint: https://10.96.0.20:12379
    size: 1 ## << EDIT TO "size: 5"
    version: 3.1.8
    
# save and apply:
sudo kubectl apply -f ${HOME}/bootkube-ci/etcd-cluster-resize.yaml
```


## Default Behavior

The default behavior for this small project is to deploy the following:

* Kubernetes [v1.7.5](https://github.com/kubernetes/kubernetes/releases/tag/v1.7.5)
* Ceph is available as part of `deploy-addons/openstack-helm-up` (look for and source the .osh_env file in that directory)
* AIO and Multi-node self-hosted Kubernetes cluster using [Bootkube](https://github.com/kubernetes-incubator/bootkube)
* Deploy Calico or Canal CNI/SDN with etcd for the Calico Policy Controller (POD_CIDR='10.25.0.0/16' and SVC_CIDR='10.96.0.0/16')
* Kubernetes API endpoint can be discovered locally at https://kubernetes.default:8443


## Calico L3

For Calico to work correctly, you will need to change the following flags in the `bootkube-up.sh` script:

```
export NSERVER01='10.96.0.10'               ### MODIFY FOR CEPH PVC         ###
export KUBE_SDN='calico'                    ### SDN SELECTION               ###
export KUBE_POD_CIDR='10.25.0.0/16'         ### SDN POD CIDR RANGE          ###
export KUBE_SVC_CIDR='10.96.0.0/16'         ### SDN SERVICE CIDR RANGE      ###
export KUBE_DNS_API='kubernetes.default'    ### DNS API ENDPOINT            ###
```

## Canal L2

For Canal to work correctly, change these flags to the following:

```
export NSERVER01='10.3.0.10'                ### MODIFY FOR CEPH PVC         ###
export KUBE_SDN='canal'                     ### SDN SELECTION               ###
export KUBE_POD_CIDR='10.2.0.0/16'          ### SDN POD CIDR RANGE          ###
export KUBE_SVC_CIDR='10.3.0.0/24'          ### SDN SERVICE CIDR RANGE      ###
export KUBE_DNS_API='kubernetes'            ### DNS API ENDPOINT            ###
```

## Additional Custom Options:

Two areas should be considered for customizing the Bootkube-CI deployment. The first area that may need modified are the variables at the top of the `bootkube-up.sh` script. The second place you may want to consider is related to the deployed SDN manifests in the [deploy-sdn](./deploy-sdn) folder. Feel free to submit an issue, or contact me on [Kubernetes Slack](https://kubernetes.slack.com/) (`v1k0d3n`).

## Adding additional Architectures:

Both amd64 and arm64 are currently supported. Please refer to the `.bootkube_env` file.

## TODO:

This repo is in heavy development at this time. It is understood that several improvements can be made. If you have any feature requests or comments, please feel free to submit a pull request of create an issue.
