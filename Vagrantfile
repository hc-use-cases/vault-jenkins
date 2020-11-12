# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  (1..3).each do |i|
    config.vm.define vm_name="consul#{i}" do |node|
      node.vm.box = "apopa/bionic64"
      node.vm.hostname = vm_name
      node.vm.network "public_network", ip: "192.168.178.#{30+i}", bridge: "en7: Dell Universal Dock D6000"
      node.vm.provision "shell", path: "scripts/consul_server.sh"
    end
  end
  
  config.vm.define vm_name="vault" do |vault|
    vault.vm.box = "apopa/bionic64"
    vault.vm.hostname = vm_name
    vault.vm.network "public_network", ip: "192.168.178.40", bridge: "en7: Dell Universal Dock D6000"
    vault.vm.provision "shell", path: "scripts/consul_client.sh"
    vault.vm.provision "shell", path: "scripts/vault_server.sh"
    vault.vm.provision "shell", path: "scripts/vault_unseal.sh"
  end

  config.vm.define vm_name="jenkins" do |jenkins|
    jenkins.vm.box = "apopa/bionic64"
    jenkins.vm.hostname = vm_name
    jenkins.vm.network "public_network", ip: "192.168.178.60", bridge: "en7: Dell Universal Dock D6000"
    jenkins.vm.provision "shell", path: "https://raw.githubusercontent.com/andrewpopa/bash-provisioning/main/jenkins/jenkins.sh"
  end

end
