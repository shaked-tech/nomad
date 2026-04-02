# Nomad Client 1 Configuration

server {
  enabled = false
}

client {
  enabled = true
  servers = ["127.0.0.1:4647"]

  meta {
    node_name = "client-1"
  }

  options = {
    "fingerprint.denylist" = "env_aws,env_gce,env_azure,env_digitalocean"
  }

  host_volume "nomad-ops-data" {
    path      = "/tmp/nomad/volumes/nomad-ops"
    read_only = false
  }

  cpu_total_compute = 2000
  memory_total_mb   = 8192

  host_network "default" {
    cidr = "127.0.0.0/8"
  }
}

bind_addr = "127.0.0.1"

advertise {
  http = "127.0.0.1"
  rpc  = "127.0.0.1"
  serf = "127.0.0.1"
}

addresses {
  http = "127.0.0.1"
}

ports {
  http = 5656
  rpc  = 5657
  serf = 5658
}

data_dir = "/tmp/nomad/client1"

log_level = "INFO"
