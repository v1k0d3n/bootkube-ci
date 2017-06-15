# -*- mode: ruby -*-
# vi: set ft=ruby :
#
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
missing_plugins_installed = false
required_plugins = %w(vagrant-proxyconf)
required_plugins.each do |plugin|
  if !Vagrant.has_plugin? plugin
    system "vagrant plugin install #{plugin}"
    missing_plugins_installed = true
  end
end
# If any plugins were missing and have been installed, re-run vagrant
if missing_plugins_installed
  exec "vagrant #{ARGV.join(" ")}"
end
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
### EDIT THE FOLLOWING FOR PROXY ENVIRONMENTS:
#    config.proxy.http     = "http://proxy.domain.com:8080/"
#    config.proxy.https    = "http://proxy.domain.com:8080/"
#    config.proxy.no_proxy = "localhost,127.0.0.1,10.0.2.15,svc.cluster.local,kubernetes.default,kubernetes"
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    git clone https://github.com/v1k0d3n/bootkube-ci.git
    cd bootkube-ci
    cat <<EOF > .bootkube_env
### REPARE THE ENVIRONMENT:
export PROXY_ENABLED=true                   ### BOOTKUBE-CI DIRECTORY       ###
export BOOTKUBE_DIR='/home/vagrant'         ### BOOTKUBE-CI DIRECTORY       ###
export CNI_VERSION=v0.5.2                   ### CNI VERSION                 ###
export HELM_VERSION=v2.3.1                  ### HELM VERSION                ###
export BOOTKUBE_VERSION=v0.4.4              ### BOOTKUBE VERSION            ###
export KUBERNETES_VERSION=v1.6.4            ### KUBERNETES VERSION          ###
export KUBE_SDN='calico'                    ### SDN SELECTION               ###
export KUBE_POD_CIDR='10.25.0.0/16'         ### SDN POD CIDR RANGE          ###
export KUBE_SVC_CIDR='10.96.0.0/16'         ### SDN SERVICE CIDR RANGE      ###
export KUBE_HW='enp0s3'                     ### MODIFY FOR IFCONFIG HW INT  ###
export KUBE_DNS_API='kubernetes.default'    ### DNS API ENDPOINT            ###
export NSERVER01='10.96.0.10'               ### NEEDS TO BE CLUSTER DNS IP  ###
export NSERVER02='10.0.2.3'                 ### THE PRIMARY DNS SERVER      ###
export NSERVER03='8.8.8.8'                  ### THE SECONDARY DNS SERVER    ###
export NSEARCH01='svc.cluster.local'        ### MODIFY FOR YOUR ENVIRONMENT ###
export NSEARCH02='default.local'            ### MODIFY FOR YOUR ENVIRONMENT ###
export KUBE_IMAGE='v1k0d3n/hyperkube-amd64' ### MODIFY FOR YOUR ENVIRONMENT ###
export KUBE_IP='10.0.2.15'                  ###
EOF
    ./bootkube-up.sh
SHELL
end
