#!/bin/bash

# Print a message indicating the start of the Vault login process
echo "Logging into Vault"

# Set the Vault address environment variable
export VAULT_ADDR='http://127.0.0.1:8200'

# Login to Vault using the root token
vault login root

echo "Step 1: Generate root CA"

# Enable the PKI secrets engine
vault secrets enable pki

# Tune the PKI secrets engine with a maximum lease time
vault secrets tune -max-lease-ttl=87600h pki

# Generate the root CA certificate and save it to a file
vault write -field=certificate pki/root/generate/internal \
    common_name="dc1.consul" \
    issuer_name="root-2023" \
    ttl=87600h > root_2023_ca.crt

# Read the issuer details and display the last 6 lines
vault read pki/issuer/$(vault list -format=json pki/issuers/ | jq -r '.[]') | tail -n 6

# Create a role with the ability to issue certificates with any name
vault write pki/roles/2023-servers allow_any_name=true

# Configure the PKI URLs for issuing certificates and CRL distribution points
vault write pki/config/urls \
    issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
    crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

echo "Step 2: Generate intermediate CA"

# Enable the PKI secrets engine at a custom path for the intermediate CA
vault secrets enable -path=pki_int pki

# Tune the intermediate PKI secrets engine with a maximum lease time
vault secrets tune -max-lease-ttl=43800h pki_int

# Generate an intermediate CA certificate signing request (CSR) and save it to a file
vault write -format=json pki_int/intermediate/generate/internal \
    common_name="dc1.consul Intermediate Authority" \
    issuer_name="dc-dot-consul-intermediate" | jq -r '.data.csr' > pki_intermediate.csr

# Sign the intermediate CA CSR with the root CA and save the certificate to a file
vault write -format=json pki/root/sign-intermediate \
    issuer_ref="root-2023" \
    csr=@pki_intermediate.csr \
    format=pem_bundle \
    ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem

# Set the signed intermediate CA certificate in Vault
vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem

echo "Step 3: Create a role"

# Create a role in the intermediate PKI engine for issuing certificates
vault write pki_int/roles/dc1-dot-consul \
    issuer_ref="$(vault read -field=default pki_int/config/issuers)" \
    allowed_domains="dc1.consul" \
    allow_subdomains=true \
    max_ttl="720h"

echo "Step 4: Request certificates"

# Issue a certificate for a specific common name with a specified TTL
vault write pki_int/issue/dc1-dot-consul common_name="server.dc1.consul" ttl="24h"
