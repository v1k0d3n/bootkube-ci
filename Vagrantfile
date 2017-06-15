# -*- mode: ruby -*-
# vi: set ft=ruby :
# Use plugins after install / re-run
# Install any Required Plugins
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
#    config.proxy.http     = "http://proxy.domain.com:8080/"
#    config.proxy.https    = "http://proxy.domain.com:8080/"
#    config.proxy.no_proxy = "localhost,127.0.0.1,10.0.2.15,svc.cluster.local,kubernetes.default,kubernetes"
end
