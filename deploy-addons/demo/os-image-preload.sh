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

export OS_IMAGE_TAG=3.0.3
export ACTION=pull

echo_yellow "\nAttempting to load Kubernetes Entrypoint image into Docker:"
sudo docker ${ACTION} quay.io/stackanetes/kubernetes-entrypoint:v0.2.1

echo_yellow "\nAttempting to load standard Ubuntu image into Docker:"
sudo docker ${ACTION} docker.io/ubuntu:16.04

echo_yellow "\nAttempting to load Rally image into Docker:"
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-rally:4.0.0

echo_yellow "\nAttempting to load Ceph images into Docker:"
sudo docker ${ACTION} quay.io/attcomdev/ceph-daemon:tag-build-master-jewel-ubuntu-16.04
sudo docker ${ACTION} docker.io/port/ceph-config-helper:v1.7.5
sudo docker ${ACTION} quay.io/external_storage/rbd-provisioner:v0.1.1

echo_yellow "\nAttempting to load Cinder images into Docker:"
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-cinder-api:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-cinder-scheduler:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-cinder-volume:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-cinder-backup:${OS_IMAGE_TAG}

echo_yellow "\nAttempting to load Etcd image into Docker:"
sudo docker ${ACTION} gcr.io/google_containers/etcd-amd64:2.2.5

echo_yellow "\nAttempting to load Glance images into Docker:"
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-glance-api:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-glance-registry:${OS_IMAGE_TAG}

echo_yellow "\nAttempting to load Heat images into Docker:"
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-heat-engine:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-heat-api:${OS_IMAGE_TAG}

echo_yellow "\nAttempting to load Horizon images into Docker:"
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-horizon:4.0.0

echo_yellow "\nAttempting to load Ingress images into Docker:"
sudo docker ${ACTION} gcr.io/google_containers/nginx-ingress-controller:0.9.0-beta.8
sudo docker ${ACTION} gcr.io/google_containers/defaultbackend:1.0

echo_yellow "\nAttempting to load Keystone images into Docker:"
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-keystone:${OS_IMAGE_TAG}

echo_yellow "\nAttempting to load Libvirt images into Docker:"
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-nova-libvirt:${OS_IMAGE_TAG}

echo_yellow "\nAttempting to load MariaDB images into Docker:"
sudo docker ${ACTION} docker.io/mariadb:10.1.23

echo_yellow "\nAttempting to load Memcache images into Docker:"
sudo docker ${ACTION} docker.io/memcached:1.4

echo_yellow "\nAttempting to load Neutron images into Docker:"
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-neutron-server:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-neutron-dhcp-agent:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-neutron-metadata-agent:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-neutron-l3-agent:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-neutron-openvswitch-agent:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-neutron-linuxbridge-agent:${OS_IMAGE_TAG}

echo_yellow "\nAttempting to load Nova images into Docker:"
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-nova-api:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-nova-conductor:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-nova-scheduler:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-nova-novncproxy:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-nova-consoleauth:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-nova-compute:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-nova-ssh:${OS_IMAGE_TAG}

echo_yellow "\nAttempting to load OpenVSwitch images into Docker:"
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-openvswitch-db-server:${OS_IMAGE_TAG}
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-openvswitch-vswitchd:${OS_IMAGE_TAG}

echo_yellow "\nAttempting to load RabbitMQ images into Docker:"
sudo docker ${ACTION} quay.io/attcomdev/fuel-mcp-rabbitmq:ocata-unstable

echo_yellow "\nAttempting to load essential tool images into Docker:"
sudo docker ${ACTION} docker.io/kolla/ubuntu-source-kolla-toolbox:${OS_IMAGE_TAG}

echo_green "\nCOMPLETE!"
