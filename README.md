# Consul Vault PKI

Consul running in Kubernetes using Vault PKI as a Certificate Authority (CA)

## Prerequisites

Before you begin, ensure you have the following prerequisites set up:

- **Kubernetes Cluster**: You need a running Kubernetes cluster. In this example, we are using Kubernetes with Docker Desktop, but any Kubernetes distribution should work.
  - For setting up Kubernetes with Docker Desktop, refer to the [Docker Desktop documentation](https://docs.docker.com/desktop/kubernetes/).

- **Helm**: Make sure Helm is installed on your machine for managing Kubernetes applications.
  - Installation instructions can be found [here](https://helm.sh/docs/intro/install/).

- **kubectl**: The Kubernetes command-line tool, `kubectl`, should be installed and configured to communicate with your cluster.
  - Installation guide is available [here](https://kubernetes.io/docs/tasks/tools/).

- **Homebrew**: Ensure Homebrew is installed for managing software packages.
  - Installation instructions are available [here](https://brew.sh/).

## Vault

For this example, we will use a locally running Vault instance in Dev mode on Kubernetes. However, any Vault instance can be used. For production environments, it is recommended to use a production-ready Vault instance or HCP Dedicated Vault. The script below will create a PKI root and intermediate CA with a common name of `consul.local`. We will expect `server.consul.local` to be the domain for our Consul server. In a production setup, you should configure your PKI to match your organization’s structure. More details can be found [here](https://developer.hashicorp.com/vault/docs/secrets/pki).

### Run Vault

Let's run Vault in Dev mode; we will connect Consul to this later.

```bash
kubectl apply -f vault/0-vault.yaml
kubectl port-forward services/vault 8200:8200
```

### Setup Vault PKI

In a different terminal, run the setup script. This will log you into Vault, enable the PKI secrets engine, generate and configure a root CA, create an intermediate CA, define a role for issuing certificates, and finally request a certificate for a specified common name. This setup ensures a complete PKI infrastructure in Vault, allowing you to manage and issue certificates securely.

```bash
sh setup-vault-pki.sh
```

This script creates three certificate files:

1. **pki_intermediate.csr**:
   - This file contains a Certificate Signing Request (CSR) for the intermediate CA. A CSR is a message sent from an applicant to a Certificate Authority, requesting a new certificate. It includes information such as the applicant's distinguished name, public key, and desired attributes of the certificate.

2. **root_2023_ca.crt**:
   - This file contains the root CA certificate. The root CA is the top-level certificate in a Public Key Infrastructure (PKI) hierarchy. It is self-signed and used to sign other certificates, including intermediate CAs.

3. **intermediate.cert.pem**:
   - This file contains the signed certificate for the intermediate CA. After generating a CSR for the intermediate CA (`pki_intermediate.csr`), the script sends this CSR to the root CA (`root_2023_ca.crt`) for signing. The signed certificate is saved as `intermediate.cert.pem`.

Now let's add the Root CA Certificate to Keychain:
- Open Keychain Access (`/Applications/Utilities/Keychain Access.app`).
- Drag and drop the `root_2023_ca.crt` file into the "System" or "System Roots" keychain.
- Double-click the certificate in Keychain Access and set the "Trust" settings to "Always Trust".

By adding the root CA certificate to your Keychain, you establish trust for certificates issued by the intermediate CA. This is because the intermediate CA's certificate (`intermediate.cert.pem`) is signed by the root CA, and trust is inherited from the root CA.

### Setup Vault Auth Methods

Now we need to set up some Auth Methods in Vault for Consul to use to access Vault's PKI Secrets Engine. First, create the policy:

```bash
sh setup-vault-auth.sh
```

## Consul

### Observability Suite (optional)

First, we'll set up the Observability Suite, which includes Prometheus and Grafana. These tools are not required but are nice to have for monitoring Consul environments. To configure this, run the following:

```bash
sh install-observability-suite.sh
```

### Install Consul

To install Consul, follow the steps below. This will set up the necessary tools and repositories, ensuring your environment is ready for Consul's deployment and management on Kubernetes.

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/consul-k8s
helm repo add hashicorp https://helm.releases.hashicorp.com
brew upgrade
brew upgrade --cask
```

### Setup Consul

```bash
consul-k8s install -f helm/consul.yaml
```

### Access Consul

Set up a port forward from localhost 8081 to the consul-ui service on port 443:

```bash
kubectl -n consul port-forward service/consul-ui 8081:443
```

Then you should be able to access the Consul UI via [https://127.0.0.1:8081](https://127.0.0.1:8081).

## See Also

- [PKI secrets engine](https://developer.hashicorp.com/vault/docs/secrets/pki)
- [Consul Helm Chart Reference](https://developer.hashicorp.com/consul/docs/k8s/helm)
- [Consul Helm Chart Reference - Vault CA](https://developer.hashicorp.com/consul/docs/k8s/helm#v-global-secretsbackend-vault-connectca)
- [Vault as Consul service mesh certification authority](https://developer.hashicorp.com/consul/tutorials/operate-consul/vault-pki-consul-connect-ca)
- [Generate mTLS Certificates for Consul with Vault](https://developer.hashicorp.com/consul/tutorials/operate-consul/vault-pki-consul-secure-tls?productSlug=consul&tutorialSlug=vault-secure&tutorialSlug=vault-pki-consul-secure-tls)

## Further Reading

- [What Is Public Key Infrastructure (PKI)? - Video](https://youtu.be/uVaUgrxjMe0?feature=shared)
- [What Is An SSL/TLS Certificate?](https://aws.amazon.com/what-is/ssl-certificate/)
- [SSL/TLS Explained in 7 Minutes - Video](https://youtu.be/67Kfsmy_frM?feature=shared)

## TODO

- [ ] Add Vault mTLS [guide](https://developer.hashicorp.com/consul/tutorials/operate-consul/vault-pki-consul-secure-tls?productSlug=consul&tutorialSlug=vault-secure&tutorialSlug=vault-pki-consul-secure-tls)