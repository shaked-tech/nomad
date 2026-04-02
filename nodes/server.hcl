# Nomad Server Configuration
# Single server for local development

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = false
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
  http = 4646
  rpc  = 4647
  serf = 4648
}

data_dir = "/tmp/nomad/server"

log_level = "INFO"
