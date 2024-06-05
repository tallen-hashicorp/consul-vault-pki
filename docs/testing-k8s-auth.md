# Testing K8s auth *(optional)*

This is not required, it just helps me test k8s auth in Vault.

## Apply Ubuntu Pod Configuration

Apply the Ubuntu pod configuration in the `consul` namespace.
```bash
kubectl -n consul apply -f k8s/ubuntu.yaml
```

## Access the Ubuntu Pod

Open a shell session in the Ubuntu pod.
```bash
kubectl -n consul exec -ti ubuntu -- /bin/sh
```

## Set Kubernetes Token and Vault Address

Retrieve the Kubernetes token and set the Vault address.
```bash
export KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
export VAULT_ADDR='http://vault.default.svc.cluster.local:8200'
```

## Authenticate with Vault

Install Curl.
```bash
apt update
apt install curl
```

Send a POST request to authenticate with Vault using the Kubernetes token.
```bash
curl --request POST --data '{"jwt": "'"$KUBE_TOKEN"'", "role": "consul"}' $VAULT_ADDR/v1/auth/kubernetes/login
```

## Install Vault on Ubuntu Pod

Update the package list, install required packages, add HashiCorp GPG key and repository, then install Vault.
```bash
apt update 
apt install gpg 
apt install wget
apt-get update && apt-get install -y lsb-release && apt-get clean all
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt install vault
```

## Authenticate with Vault Using the Token

Authenticate with Vault using the previously retrieved Kubernetes token.
```bash
vault write auth/kubernetes/login role=consul jwt=$KUBE_TOKEN
```

## Clean up 
```
kubectl -n consul delete -f k8s/ubuntu.yaml
```