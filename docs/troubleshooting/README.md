## Removing Failed Bootkube Items

Occasionally during the "up" phase, either a `kube-controller-manager` or a `kube-scheduler` will be stuck in a "CrashLoopBackOff" condition. Less often, you may be both a controller *and* and scheduler in this condition. This is fine if it occurs for 1/2 of the deployed items. To correct this behavior, do the following:

**Controller-Manager:**

```
export FAILED_KUBE_CONTROLLER=`sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig get pods -n kube-system --no-headers 2>/dev/null | grep "CrashLoopBackOff" | grep "kube-controller-manager" | cut -d " " -f1`

sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig delete po/"$FAILED_KUBE_CONTROLLER" -n kube-system
```

**Scheduler:**

```
export FAILED_KUBE_SCHEDULER=`sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig get pods -n kube-system --no-headers 2>/dev/null | grep "CrashLoopBackOff" | grep "kube-scheduler" | cut -d " " -f1`

sudo kubectl --kubeconfig=/etc/kubernetes/kubeconfig delete po/"$FAILED_KUBE_SCHEDULER" -n kube-system
```

When using this repository for Bootkube-CI, you should not have to worry about this condition. You will only need to be concerned when *all* controllers or schedulers are in a "CrashLoopBackOff" state, as this condition may not be recoverable or will be unstable. You will really only need to run the above statements in cases where you're using this repository for development purposes.
