job "nomad-ops" {
  namespace   = "default"
  datacenters = ["dc1"]
  type        = "service"

  update {
    stagger      = "30s"
    max_parallel = 1
  }

  group "nomad-ops" {
    count = 1

    volume "data" {
      type   = "host"
      source = "nomad-ops-data"
    }

    network {
      mode = "host"
      port "http" {
        static = 8080
      }
    }

    service {
      name     = "nomad-ops"
      port     = "http"
      provider = "nomad"

      check {
        type     = "http"
        path     = "/api/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "operator" {
      driver = "docker"

      volume_mount {
        volume      = "data"
        destination = "/data"
      }

      env {
        NOMAD_ADDR               = "http://host.docker.internal:4646"
        NOMAD_OPS_LOCAL_REPO_DIR = "/data/repos"
        SSL_CERT_FILE            = "/data/ca-certificates.crt"
        TRACE                    = "FALSE"
      }

      config {
        image = "ghcr.io/nomad-ops/nomad-ops:main"
        args = [
          "serve",
          "--http", "0.0.0.0:${NOMAD_PORT_http}",
          "--dir", "/data/pb_data",
        ]

        ports = ["http"]
      }

      resources {
        cpu    = 200
        memory = 500
      }
    }
  }
}
