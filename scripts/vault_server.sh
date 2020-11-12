#!/usr/bin/env bash

# we want the scrip to be verbose
set -x

# install packages if not installed
which curl wget unzip jq &>/dev/null || {
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update
  sudo apt-get install --no-install-recommends -y curl wget unzip jq
}

# get current version of consul that is not beta/alpha
VAULTVER=$(curl -sL https://releases.hashicorp.com/vault/index.json | jq -r '.versions[].version' | sort -V | egrep -v 'ent|beta|rc|alpha' | tail -n1)

# check if vault is installed
# if not, download and configure service
which vault &>/dev/null || {

  echo Installing vault ${VAULTVER}
  wget https://releases.hashicorp.com/vault/${VAULTVER}/vault_${VAULTVER}_linux_amd64.zip
  unzip vault_${VAULTVER}_linux_amd64.zip
  sudo mv vault /usr/local/bin/
  vault -autocomplete-install
  sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

  # create vault user
  sudo useradd --system --home /etc/vault.d --shell /bin/false vault

  # copy vault configuration
  sudo cp /vagrant/conf/vault.service /etc/systemd/system/vault.service
  sudo mkdir -p /etc/vault
  sudo cp /vagrant/conf/vault_server.hcl /etc/vault/vault_server.hcl
  
  # adjust vault config
  sudo sed -i "s/localhost/$(hostname -I | grep -E -o "(192)\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})")/g" /etc/vault/vault_server.hcl

  # enable and start service  
  sudo systemctl enable vault
  sudo systemctl start vault
  export VAULT_ADDR=http://127.0.0.1:8200
  # status will fail as its sealed
  vault status || true
}
