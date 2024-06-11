#!/bin/bash

# Set the Vault address environment variable
export VAULT_ADDR='http://127.0.0.1:8200'

# Login to Vault using the root token
vault login root

# Enable the KV secrets engine at the specified path
vault secrets enable -path=consul kv-v2

# Generate a Consul gossip encryption key and store it in Vault
vault kv put consul/secrets/gossip key=$(consul keygen)

# Write a Vault policy for Consul CA from the specified HCL file
vault policy write consul-ca vault/vault-policy-consul-ca.hcl

# Apply the Vault Kubernetes authentication service account configuration
kubectl apply -f k8s/vault-auth-service-account.yaml

# Apply the Vault Kubernetes authentication secret configuration
kubectl apply -f k8s/vault-auth-secret.yaml

# Create a namespace for Consul and apply the service account configuration
kubectl create ns consul
kubectl -n consul apply -f k8s/consul-service-account.yaml

# Extract the name of the service account secret
export SA_SECRET_NAME=$(kubectl get secrets --output=json \
    | jq -r '.items[].metadata | select(.name|startswith("vault-auth-")).name')

# Extract the JWT token from the service account secret
export SA_JWT_TOKEN=$(kubectl get secret $SA_SECRET_NAME \
    --output 'go-template={{ .data.token }}' | base64 --decode)

# Extract the Kubernetes CA certificate
export SA_CA_CRT=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)

# Extract the Kubernetes API server URL
export K8S_HOST=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.server}')

# Print the extracted values for verification
echo "Service Account Secret Name: $SA_SECRET_NAME"
echo "Service Account JWT Token: $SA_JWT_TOKEN"
echo "Service Account CA Certificate: $SA_CA_CRT"
echo "Kubernetes Host: $K8S_HOST"

# Enable the Kubernetes authentication method in Vault
vault auth enable kubernetes

# Configure Vault Kubernetes authentication with the extracted values
vault write auth/kubernetes/config \
     token_reviewer_jwt="$SA_JWT_TOKEN" \
     kubernetes_host="$K8S_HOST" \
     kubernetes_ca_cert="$SA_CA_CRT"

# Create a Vault role for Consul server with the appropriate policies and TTL
vault write auth/kubernetes/role/consul \
     bound_service_account_names=consul-server \
     bound_service_account_namespaces=consul \
     token_policies=consul-ca \
     ttl=24h

# Create a Vault role for Consul server testing with the appropriate policies and TTL
vault write auth/kubernetes/role/consul-test \
     bound_service_account_names=consul-server-test \
     bound_service_account_namespaces=consul \
     token_policies=consul-ca \
     ttl=24h

# Enable Vault audit logging to a file
vault audit enable file file_path=/tmp/vault_audit.log
