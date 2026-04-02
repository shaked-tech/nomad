job "traefik" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      port "http" {
        static = 80
      }
      port "api" {
        static = 8081
      }
    }

    service {
      name     = "traefik-http"
      port     = "http"
      provider = "nomad"
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v3.3"
        ports = ["http", "api"]
        volumes = [
          "local/traefik.yaml:/etc/traefik/traefik.yaml",
          "local/dynamic.yaml:/etc/traefik/dynamic.yaml",
        ]
      }

      template {
        data = <<-YAML
          api:
            dashboard: true
            insecure: true
          entryPoints:
            web:
              address: ":80"
            traefik:
              address: ":8081"
          providers:
            file:
              filename: /etc/traefik/dynamic.yaml
              watch: true
        YAML
        destination = "local/traefik.yaml"
      }

      # Dynamic config generated from Nomad service catalog
      template {
        data = <<-EOF
          http:
            routers:
              nomad-ops:
                rule: "Host(`nomad-ops.localhost`)"
                entrypoints: ["web"]
                service: nomad-ops
              vote:
                rule: "Host(`vote.localhost`)"
                entrypoints: ["web"]
                service: vote
              result:
                rule: "Host(`result.localhost`)"
                entrypoints: ["web"]
                service: result
            services:
              nomad-ops:
                loadBalancer:
                  servers:
                  {{ range nomadService "nomad-ops" }}
                    - url: "http://host.docker.internal:{{ .Port }}"
                  {{ end }}
              vote:
                loadBalancer:
                  servers:
                  {{ range nomadService "vote" }}
                    - url: "http://host.docker.internal:{{ .Port }}"
                  {{ end }}
              result:
                loadBalancer:
                  servers:
                  {{ range nomadService "result" }}
                    - url: "http://host.docker.internal:{{ .Port }}"
                  {{ end }}
        EOF
        destination = "local/dynamic.yaml"
        change_mode = "noop"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
