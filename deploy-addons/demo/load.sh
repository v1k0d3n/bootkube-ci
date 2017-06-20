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
### Declare colors to use during the running of this script:
declare -r GREEN="\033[0;32m"
declare -r RED="\033[0;31m"
declare -r YELLOW="\033[0;33m"

function echo_green {
  echo -e "${GREEN}$1"; tput sgr0
}
function echo_red {
  echo -e "${RED}$1"; tput sgr0
}
function echo_yellow {
  echo -e "${YELLOW}$1"; tput sgr0
}


## NEW INSTALLATIONS:
echo_green "\nPhase I: Installing system prerequisites:"
image="docker.io/ceph/daemon:tag-build-master-jewel-ubuntu-16.04
       quay.io/v1k0d3n/ceph-daemon:tag-build-master-jewel-ubuntu-16.04
       docker.io/kolla/ubuntu-source-kubernetes-entrypoint:4.0.0
       gcr.io/google_containers/etcd-amd64:2.2.5
       gcr.io/google_containers/nginx-ingress-controller:0.8.3
       gcr.io/google_containers/defaultbackend:1.0
       mariadb:10.1.23
       docker.io/memcached:1.4
       docker.io/kolla/ubuntu-binary-rally:4.0.0
       docker.io/kolla/ubuntu-source-kolla-toolbox:3.0.3
       docker.io/kolla/ubuntu-source-cinder-api:3.0.3
       docker.io/kolla/ubuntu-source-cinder-scheduler:3.0.3
       docker.io/kolla/ubuntu-source-cinder-volume:3.0.3
       docker.io/kolla/ubuntu-source-cinder-backup:3.0.3
       docker.io/kolla/ubuntu-source-glance-api:3.0.3
       docker.io/kolla/ubuntu-source-glance-registry:3.0.3
       docker.io/kolla/ubuntu-source-heat-api:3.0.3
       docker.io/kolla/ubuntu-source-heat-engine:3.0.3
       docker.io/kolla/ubuntu-source-horizon:3.0.3
       docker.io/kolla/ubuntu-source-keystone:3.0.3
       docker.io/kolla/ubuntu-source-neutron-server:3.0.3
       docker.io/kolla/ubuntu-source-neutron-dhcp-agent:3.0.3
       docker.io/kolla/ubuntu-source-neutron-metadata-agent:3.0.3
       docker.io/kolla/ubuntu-source-neutron-l3-agent:3.0.3
       docker.io/kolla/ubuntu-source-neutron-openvswitch-agent:3.0.3
       docker.io/kolla/ubuntu-source-openvswitch-db-server:3.0.3
       docker.io/kolla/ubuntu-source-openvswitch-vswitchd:3.0.3
       docker.io/kolla/ubuntu-source-nova-api:3.0.3
       docker.io/kolla/ubuntu-source-nova-conductor:3.0.3
       docker.io/kolla/ubuntu-source-nova-scheduler:3.0.3
       docker.io/kolla/ubuntu-source-nova-novncproxy:3.0.3
       docker.io/kolla/ubuntu-source-nova-consoleauth:3.0.3
       docker.io/kolla/ubuntu-source-nova-compute:3.0.3
       docker.io/kolla/ubuntu-source-nova-libvirt:3.0.3
       docker.io/kolla/ubuntu-source-nova-api:3.0.3
       quay.io/attcomdev/fuel-mcp-rabbitmq:ocata-unstable
       quay.io/stackanetes/kubernetes-entrypoint:v0.1.1"

for image in $image; do
    sudo docker pull $image
done
