ui            = true
cluster_addr  = "https://192.168.88.43:8201"
api_addr      = "https://192.168.88.43:8200"
disable_mlock = true

storage "raft" {
  path = "/Users/rdchome/repositories/home-network-config/vault/data"
  node_id = "raft_node_id"
}

listener "tcp" {
  address       = "192.168.88.43:8200"
  tls_cert_file = "/Users/rdchome/repositories/home-network-config/vault/vault-cert.pem"
  tls_key_file  = "/Users/rdchome/repositories/home-network-config/vault/vault-key.pem"
}
