Bootkube-CI is a simple Kubernetes environment that can be used for a number of CI, development and/or demonstration scenarios.

# Deployment Instructions:

If you wish to use this repository for CI or for bringing up a Kubernetes cluster, simply clone and edit the `bootkube-up.sh` script. Currently, two SDN's are optional and included (Calico is default).

Included with this repository are the concepts of "add-ons": other deployment tests that you may want to run in sequence with a Kubernetes self-hosted cluster. Using these are just as simple and straight-forward as using the deployment itself. So if you wanted to deploy [openstack-helm](https://github.com/openstack/openstack-helm) for example,  all that would be required is the following:

```
git clone https://github.com/v1k0d3n/bootkube-ci.git

## make any variable modifications via your CI platform of choice to both bootkube-up.sh and ./deploy-addons/openstack-helm-up.sh
## and deploy

./bootkube-ci/bootkube-up.sh
./bootkube-ci/deploy-addons/openstack-helm-up.sh

# done
```

## Default Behavior

The default behavior for this small project is to deploy the following:

* Kubernetes [v1.6.2](https://github.com/kubernetes/kubernetes/releases/tag/v1.6.2) with `ceph-common` installed in the [Hyperkube](https://quay.io/repository/v1k0d3n/hyperkube-amd64?tab=tags) container (for Ceph PVC support)
* All-In-One self-hosted Kubernetes cluster using [Bootkube](https://github.com/kubernetes-incubator/bootkube) (both for render and start)
* Deploy Calico CNI/SDN with etcd for the Calico Policy Controller (POD_CIDR='10.25.0.0/16' and SVC_CIDR='10.96.0.0/16')
* Kubernetes API endpoint can be discovered locally at https://kubernetes.default:443

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

## TODO:

This repo is in heavy development at this time. It is understood that several improvements can be made. If you have any feature requests or comments, please feel free to submit a pull request of create an issue.
