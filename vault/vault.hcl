ui            = true
cluster_addr  = "http://0.0.0.0:8201"
api_addr      = "http://0.0.0.0:8200"
disable_mlock = true

storage "postgresql" {
  connection_url = "postgresql://vault:vault@postgres:5432/vault"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable = 1
}