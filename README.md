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

## Creating Client Certificates

Currently, this project uses the kubeconfig (user: kubelet) for communicating with the cluster. In a more production environment, you will want to consider creating authenticated client certificates to communicate with the cluster. To do this, as an example, perform the following additional tasks (we will make this default behavior soon):

```
## Change some permissions and move the current kubeconfig.
sudo chown -R ubuntu ~/.kube
mv ~/.kube/config ~/.kube/backup_config

## Create a temp directory for your user certs, and generate them against the bootkube generated CA.
mkdir /home/ubuntu/.kube_certs
openssl x509 -req -in /home/ubuntu/.kube_certs/admin.csr \
  -CA /home/ubuntu/.bootkube/tls/ca.crt \
  -CAkey /home/ubuntu/.bootkube/tls/ca.key \
  -CAcreateserial -out /home/ubuntu/.kube_certs/admin.pem -days 365

## Next, create a ~/.kube/config.
sudo kubectl config --kubeconfig=/etc/kubernetes/kubeconfig \
    set-cluster default-cluster --server=https://192.168.4.51:8443 \
    --certificate-authority=/home/ubuntu/.bootkube/ca.crt

kubectl config set-credentials ubuntu \
    --certificate-authority=/home/ubuntu/.bootkube/ca.crt \
    --client-key=/home/ubuntu/.kube_certs/admin-key.pem \
    --client-certificate=/home/ubuntu/.kube_certs/admin.pem   

kubectl config set-context default-system --cluster=default-cluster --user=ubuntu
kubectl config use-context default-system
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
