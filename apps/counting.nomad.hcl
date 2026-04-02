job "counting" {
  namespace   = "default"
  datacenters = ["dc1"]
  type        = "service"

  group "api" {
    count = 1

    network {
      port "http" {
        to = 9001
      }
    }

    service {
      name     = "counting"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.counting.rule=PathPrefix(`/count`)",
        "traefik.http.routers.counting.entrypoints=web",
      ]
    }

    task "counting" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-api:v3"
        ports = ["http"]
      }

      env {
        PORT = "9001"
      }

      resources {
        cpu    = 50
        memory = 64
      }
    }
  }
}
