#!/bin/bash
export VAULT_ADDR='http://127.0.0.1:8200'
vault login root

vault secrets enable -path=consul kv-v2
vault kv put consul/secrets/gossip key=$(consul keygen)

vault policy write consul-ca vault/vault-policy-consul-ca.hcl

kubectl apply -f k8s/vault-auth-service-account.yaml

kubectl apply -f k8s/vault-auth-secret.yaml

kubectl create ns consul
kubectl -n consul apply -f k8s/consul-service-account.yaml


export SA_SECRET_NAME=$(kubectl get secrets --output=json \
    | jq -r '.items[].metadata | select(.name|startswith("vault-auth-")).name')
export SA_JWT_TOKEN=$(kubectl get secret $SA_SECRET_NAME \
    --output 'go-template={{ .data.token }}' | base64 --decode)
export SA_CA_CRT=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
export K8S_HOST=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.server}')

echo $SA_SECRET_NAME
echo $SA_JWT_TOKEN
echo $SA_CA_CRT
echo $K8S_HOST

vault auth enable kubernetes

vault write auth/kubernetes/config \
     token_reviewer_jwt="$SA_JWT_TOKEN" \
     kubernetes_host="$K8S_HOST" \
     kubernetes_ca_cert="$SA_CA_CRT" 

vault write auth/kubernetes/role/consul \
     bound_service_account_names=consul-server \
     bound_service_account_namespaces=consul \
     token_policies=consul-ca \
     ttl=24h

vault write auth/kubernetes/role/consul-test \
     bound_service_account_names=consul-server-test \
     bound_service_account_namespaces=consul \
     token_policies=consul-ca \
     ttl=24h

### Vault Audit Logging
vault audit enable file file_path=/tmp/vault_audit.log