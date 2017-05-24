Bootkube-CI is a simple Kubernetes environment that can be used for a number of CI, development and/or demonstration scenarios.

# Deployment Instructions:

If you wish to use this repository for CI or for bringing up a Kubernetes cluster, simply clone and edit the `bootkube-up.sh` script. Currently, two SDN's are optional and included (Calico is default).

## Calico L3

For Calico to work correctly, you will need to change the following flags:

```
export KUBE_SDN='canal'                     ### SDN SELECTION               ###
export KUBE_POD_CIDR='192.168.0.0/16'       ### SDN POD CIDR RANGE          ###
export KUBE_SVC_CIDR='10.96.0.0/16'         ### SDN SERVICE CIDR RANGE      ###
export KUBE_DNS_API='kubernetes.default'    ### DNS API ENDPOINT            ###
```

## Canal L2

For Canal to work correctly, you will need to change the following flags:

```
export KUBE_SDN='calico'                    ### SDN SELECTION               ###
export KUBE_POD_CIDR='10.2.0.0/16'          ### SDN POD CIDR RANGE          ###
export KUBE_SVC_CIDR='10.3.0.0/24'          ### SDN SERVICE CIDR RANGE      ###
export KUBE_DNS_API='kubernetes'            ### DNS API ENDPOINT            ###
```

## Additional Custom Options:

Two areas should be considered for customizing the Bootkube-CI deployment. The first area that may need modified are the variables at the top of the `bootkube-up.sh` script. The second place you may want to consider is related to the deployed SDN manifests in the [deploy-sdn](./deploy-sdn) folder. Feel free to submit an issue, or contact me on [Kubernetes Slack](https://kubernetes.slack.com/) (`v1k0d3n`).
