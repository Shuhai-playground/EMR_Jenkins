# For K/V v1 secrets engine
path "secret/spinnaker/*" {
    capabilities = ["read", "list"]
}
# For K/V v2 secrets engine
path "secret/data/spinnaker/*" {
    capabilities = ["read", "list"]
}