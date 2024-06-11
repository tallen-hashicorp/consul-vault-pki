path "/sys/mounts/pki" {
  capabilities = [ "read" ]
}

path "/sys/mounts/pki_int" {
  capabilities = [ "read" ]
}

path "/sys/mounts/pki_int/tune" {
  capabilities = [ "update" ]
}

path "/pki/" {
  capabilities = [ "read" ]
}

path "/pki/root/sign-intermediate" {
  capabilities = [ "update" ]
}

path "/pki_int/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

path "auth/token/renew-self" {
  capabilities = [ "update" ]
}

path "auth/token/lookup-self" {
  capabilities = [ "read" ]
}

path "consul/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
