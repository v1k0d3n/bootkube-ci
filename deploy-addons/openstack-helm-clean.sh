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
kubectl delete pvc mysql-data-mariadb-0 -n openstack
kubectl delete pvc mysql-data-mariadb-1 -n openstack
kubectl delete pvc mysql-data-mariadb-2 -n openstack
export ceph_array=`(kubectl get all -n ceph | (awk -F"," '{print $1}') | (cut -d' ' -f1) | (sed '1d') | (awk '/[^[:upper:] ]/'))`
for thing in $osh_array;do
 `kubectl delete $thing --grace-period=0 --force -n openstack`
done
export osh_array=`(kubectl get all -n openstack | (awk -F"," '{print $1}') | (cut -d' ' -f1) | (sed '1d') | (awk '/[^[:upper:] ]/'))`
for thing in $osh_array;do
 `kubectl delete $thing --grace-period=0 --force -n openstack`
done
kubectl delete namespace openstack
helm delete --purge magnum
helm delete --purge mistral
helm delete --purge senlin
helm delete --purge barbican
helm delete --purge horizon
helm delete --purge neutron
helm delete --purge nova
helm delete --purge cinder
helm delete --purge heat
helm delete --purge glance
helm delete --purge keystone
helm delete --purge memcached
helm delete --purge rabbitmq-etcd
helm delete --purge rabbitmq
helm delete --purge mariadb
helm delete --purge bootstrap-openstack
helm delete --purge bootstrap-ceph
helm delete --purge ceph
sudo rm -rf /var/lib/openstack-helm
sudo rm -rf /var/lib/nova
sudo rm -rf /home/$USER/openstack-helm
sudo rm -rf /usr/local/bin/sigil
pkill -f 'helm serve'
helm repo remove local
