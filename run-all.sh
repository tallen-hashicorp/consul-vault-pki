#!/bin/bash

# Apply the Kubernetes configuration for Vault
kubectl apply -f vault/0-vault.yaml 

# Wait for vault to start
echo "Waiting for Vault pod to be ready..."
while [[ $(kubectl get pods -l app=vault -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    echo "Waiting for Vault pod to be ready..."
    sleep 2
done
echo "Vault pod is ready."

# Start port-forwarding for Vault in the background
kubectl port-forward services/vault 8200:8200 &
PORT_FORWARD_PID=$!
echo "The PID of the port-forward process is $PORT_FORWARD_PID, I will kill it at the end of this script"

# Wait for the port forwarding to be established
sleep 5

# Execute Vault setup PKI scripts
sh setup-vault-pki.sh

# Wait for PKI to be ready
sleep 5

# Execute Vault Auth setup scripts
sh setup-vault-auth.sh

# Wait for auth to be ready
sleep 5

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install Homebrew first."
    exit 1
fi

# Check if the hashicorp/tap is already tapped
if ! brew tap | grep -q "^hashicorp/tap$"; then
    echo "Tapping hashicorp/tap..."
    brew tap hashicorp/tap
else
    echo "hashicorp/tap is already tapped."
fi

# Check if consul-k8s is already installed
if ! brew list | grep -q "^consul-k8s$"; then
    echo "Installing consul-k8s..."
    brew install hashicorp/tap/consul-k8s
else
    echo "consul-k8s is already installed."
fi

# Check if the HashiCorp Helm repository is already added
if ! helm repo list | grep -q "https://helm.releases.hashicorp.com"; then
    echo "Adding HashiCorp Helm repository..."
    helm repo add hashicorp https://helm.releases.hashicorp.com
else
    echo "HashiCorp Helm repository is already added."
fi

# Install Consul using the specified Helm values file
consul-k8s install -f helm/consul.yaml

# After your commands are done, kill the port-forward process
kill $PORT_FORWARD_PID
echo "Port forwarding has been stopped."