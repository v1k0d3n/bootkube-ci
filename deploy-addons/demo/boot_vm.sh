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

set -ex

KS_USER="charter_admin"
KS_PROJECT="ctec"
KS_PASSWORD="password"
KS_USER_DOMAIN="default"
KS_PROJECT_DOMAIN="default"
KS_URL="http://keystone.openstack/v3"

KEYSTONE_CREDS="--os-username ${KS_USER} \
  --os-project-name ${KS_PROJECT} \
  --os-auth-url ${KS_URL} \
  --os-project-domain-name ${KS_PROJECT_DOMAIN} \
  --os-user-domain-name ${KS_USER_DOMAIN} \
  --os-password ${KS_PASSWORD}"
OS_TOOLKIT=$(kubectl get -n openstack pods -l application=heat,component=engine --no-headers -o name | awk -F '/' '{ print $NF; exit }')
OS_CMD="kubectl exec -n openstack ${OS_TOOLKIT} -- openstack ${KEYSTONE_CREDS} --os-identity-api-version 3 --os-image-api-version 2"

OS_PROJECT=$($OS_CMD project show ctec -f value -c id)
OS_SEC_GROUP=$($OS_CMD security group list -f csv | grep $OS_PROJECT | grep "default" | awk -F "," '{ print $1 }'  | tr -d '"')

$OS_CMD security group rule create $OS_SEC_GROUP \
  --protocol icmp \
  --src-ip 0.0.0.0/0
$OS_CMD security group rule create $OS_SEC_GROUP \
  --protocol tcp \
  --dst-port 22:22 \
  --src-ip 0.0.0.0/0

TEST_KEY="$(mktemp).pem"
$OS_CMD keypair create "ctec-test" > $TEST_KEY
chmod 600 $TEST_KEY

VM_FLAVOR_ID=$($OS_CMD flavor show "vnf.small" -f value -c id)
VM_IMAGE_ID=$($OS_CMD image list -f csv | awk -F ',' '{ print $2 "," $1 }' | grep "^\"Cirros" | head -1 | awk -F ',' '{ print $2 }' | tr -d '"')
NETWORK_ID=$($OS_CMD network show provider-482 -f value -c id)

$OS_CMD server create --nic net-id=$NETWORK_ID \
  --flavor=$VM_FLAVOR_ID \
  --image=$VM_IMAGE_ID \
  --key-name="ctec-test" \
  --security-group=$OS_SEC_GROUP \
  "ctec-vm"

VM_ID=$($OS_CMD server list -f value -c ID)
VM_IP=$($OS_CMD server show $VM_ID -f value -c addresses | cut -f2 -d=)

sleep 20

ssh-keyscan $VM_IP >> ~/.ssh/known_hosts 

ssh -i $TEST_KEY cirros@$VM_IP ping -q -c 1 -W 2 www.google.com

ssh -i $TEST_KEY cirros@$VM_IP curl http://artscene.textfiles.com/asciiart/unicorn || true
