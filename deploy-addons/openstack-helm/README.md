# Volumes

After deploying Ceph, you will want to create the OSD pools like so:

```
kubectl exec -n ceph -it ceph-mon-0 ceph osd pool create volumes 25
kubectl exec -n ceph -it ceph-mon-0 ceph osd pool create images 15
```
