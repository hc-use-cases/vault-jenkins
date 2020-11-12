#!/usr/bin/env bash
sleep 10
pushd /vagrant
export VAULT_ADDR=http://127.0.0.1:8200
# generate unseal key
[ -f init.txt ] || {
  vault operator init -key-shares=1 -key-threshold=1 > init.txt
}
# unseal
sleep 10
vault operator unseal $(cat init.txt | grep -i "unseal key [1]" | awk '{ print $4}')
popd