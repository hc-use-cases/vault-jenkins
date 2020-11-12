ui = true
listener "tcp" {
  address          = "0.0.0.0:8200"
  cluster_address  = "localhost:8201"
  tls_disable      = "true"
}
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}
default_lease_ttl = "168h"
max_lease_ttl = "720h"
plugin_directory = "/usr/local/vault/plugins"

api_addr = "http://localhost:8200"
cluster_addr = "https://localhost:8201"
