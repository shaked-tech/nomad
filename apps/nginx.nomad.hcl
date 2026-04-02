job "nginx" {
  namespace   = "default"
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 3

    network {
      port "http" {
        to = 80
      }
    }

    service {
      name     = "nginx"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.nginx.rule=PathPrefix(`/`)",
        "traefik.http.routers.nginx.entrypoints=web",
      ]
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:latest"
        ports = ["http"]


      resources {
        cpu    = 50
        memory = 64
      }
    }
  }
}
