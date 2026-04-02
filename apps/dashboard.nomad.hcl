job "dashboard" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 1

    network {
      port "http" {
        to = 8080
      }
    }

    service {
      name     = "dashboard"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.dashboard.rule=PathPrefix(`/dashboard`) || PathPrefix(`/api`)",
        "traefik.http.routers.dashboard.entrypoints=web",
      ]
    }

    task "dashboard" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-dashboard:v3"
        ports = ["http"]
      }

      env {
        COUNTING_SERVICE_URL = "http://${NOMAD_UPSTREAM_ADDR_counting}"
        PORT                 = "8080"
      }

      resources {
        cpu    = 50
        memory = 64
      }
    }
  }
}
