# consul-vault-pki
Consul running in K8s using Vault PKI as a CA

# Vault
For this example, we will be using a locally running Vault instance in Dev mode. However, any Vault instance can be used. For production environments, it is recommended to use a production-ready Vault instance or HCP Dedicated Vault. The script below will create a PKI root and intermediate CA with a common name of `consul.local`. We will expect `server.consul.local` to be the domain for our Consul server. In a production setup, you should configure your PKI to match your organization’s normal structure. More details can be found [here](https://developer.hashicorp.com/vault/docs/secrets/pki).

## Run Vault

Lets run vault in Dev mode, we will connect consul to this later

```bash
vault server -dev -dev-root-token-id root
```

## Setup Vault PKI

Now in a different terminal, run the setup script. This will log you into Vault, enable the PKI secrets engine, generate and configure a root CA, create an intermediate CA, define a role for issuing certificates, and finally request a certificate for a specified common name. This setup ensures a complete PKI infrastructure in Vault, allowing you to manage and issue certificates securely.
```bash
sh setup-vault-pki.sh
```

this creates 4 files:

1. **pki_intermediate.csr**:
   - This file contains a Certificate Signing Request (CSR) for the intermediate CA. A CSR is a message sent from an applicant to a Certificate Authority, requesting a new certificate. It includes information such as the applicant's distinguished name, public key, and desired attributes of the certificate. In this script, `pki_intermediate.csr` is generated to request the signing of the intermediate CA certificate by the root CA.

2. **root_2023_ca.crt**:
   - This file contains the root CA certificate. The root CA is the top-level certificate in a Public Key Infrastructure (PKI) hierarchy. It is self-signed and used to sign other certificates, including intermediate CAs. The `root_2023_ca.crt` file stores the root CA certificate generated by the script. This certificate is crucial for establishing trust within the PKI infrastructure, as it is used to verify the authenticity of certificates signed by the root CA.

3. **intermediate.cert.pem**:
    - This file contains the signed certificate for the intermediate CA. After generating a Certificate Signing Request (CSR) for the intermediate CA (`pki_intermediate.csr`), the script sends this CSR to the root CA (`root_2023_ca.crt`) for signing.
    - The root CA then signs the CSR and returns the signed certificate, which is saved as `intermediate.cert.pem`.
    - The `intermediate.cert.pem` file represents the intermediate CA's certificate, which is issued by the root CA. It contains the intermediate CA's public key, along with other information such as its validity period and issuer details.
    - This intermediate CA certificate is crucial for establishing a chain of trust within the Public Key Infrastructure (PKI) hierarchy. It is used to sign end-entity certificates (e.g., website certificates) and validate their authenticity in the trust chain.

Now we have done this lets add the Root CA Certificate to Keychain
- Open Keychain Access (`/Applications/Utilities/Keychain Access.app`).
- Drag and drop the `root_2023_ca.crt` file into the "System" or "System Roots" keychain.
- Double-click the certificate in Keychain Access and set the "Trust" settings to "Always Trust".

By adding the root CA certificate to your Keychain, you establish trust for certificates issued by the intermediate CA. This is because the intermediate CA's certificate (`intermediate.cert.pem`) is signed by the root CA, and trust is inherited from the root CA.

You typically don't need to add the intermediate CA certificate separately to your trust store unless you have specific use cases that require it. The intermediate CA certificate is used by the system to validate certificates issued by the intermediate CA, but trust is ultimately established through the root CA certificate.

## Setup Vault Auth methods
Now we need to setup some Auth Methods in Vault for Consul to use to access Vaults PKI Secrets Engine. 

First lets create the policy
```bash
export VAULT_ADDR='http://127.0.0.1:8200'
vault login root
vault policy write consul-ca vault/vault-policy-consul-ca.hcl
```

TODO

# Consul

## Observability Suite *(optional)*
First we'll setup the Observability Suite this includes Prometheus, and Grafana, these are not required but are nice to have tools for monitoring Consul environments. To configure this run the following

```bash
sh install-observability-suite.sh
```

## Install Consul
To install Consul, follow the steps below. This will set up the necessary tools and repositories, ensuring your environment is ready for Consul's deployment and management on Kubernetes.

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/consul-k8s
helm repo add hashicorp https://helm.releases.hashicorp.com
brew upgrade
brew upgrade --cask
```

## Edit Consul Config File
We will use the Helm chart to install Consul, this is highly customisable using Helm configuration values. Each value has a reasonable default tuned for an optimal getting started experience with Consul, more details can be found [here](https://developer.hashicorp.com/consul/docs/k8s/helm)

TODO

## Setup Consul
```bash
consul-k8s install -f config.yaml
```

## Access Consul
TODO

# See Also
* [PKI secrets engine](https://developer.hashicorp.com/vault/docs/secrets/pki)
* [Consul Helm Chart Reference](https://developer.hashicorp.com/consul/docs/k8s/helm)
* [Consul Helm Chart Reference - Vault CA](https://developer.hashicorp.com/consul/docs/k8s/helm#v-global-secretsbackend-vault-connectca)
* [Vault as Consul service mesh certification authority](https://developer.hashicorp.com/consul/tutorials/operate-consul/vault-pki-consul-connect-ca)
* [Generate mTLS Certificates for Consul with Vault](https://developer.hashicorp.com/consul/tutorials/operate-consul/vault-pki-consul-secure-tls?productSlug=consul&tutorialSlug=vault-secure&tutorialSlug=vault-pki-consul-secure-tls)

# Further Reading
* [What Is Public Key Infrastructure (PKI)? - Video](https://youtu.be/uVaUgrxjMe0?feature=shared)
* [What Is An SSL/TLS Certificate?](https://aws.amazon.com/what-is/ssl-certificate/)
* [SSL/TLS Explained in 7 Minutes - Video](https://youtu.be/67Kfsmy_frM?feature=shared)

# TODO
[ ] Add Vault mTLS [guide](https://developer.hashicorp.com/consul/tutorials/operate-consul/vault-pki-consul-secure-tls?productSlug=consul&tutorialSlug=vault-secure&tutorialSlug=vault-pki-consul-secure-tls)
