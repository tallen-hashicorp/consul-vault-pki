#!/bin/bash
export VAULT_ADDR='http://127.0.0.1:8200'
vault login root

vault policy write consul-ca vault/vault-policy-consul-ca.hcl

