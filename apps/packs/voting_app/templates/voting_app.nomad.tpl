job "voting-app" {
  datacenters = [[ var "datacenters" . | toJson ]]
  type        = "service"

  # ─── Redis ────────────────────────────────────────────────────
  group "redis" {
    count = 1

    network {
      port "redis" {
        static = [[ var "redis_port" . ]]
        to     = 6379
      }
    }

    service {
      name     = "redis"
      port     = "redis"
      provider = "nomad"
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:alpine"
        ports = ["redis"]
      }

      resources {
        cpu    = [[ var "resources.redis_cpu" . ]]
        memory = [[ var "resources.redis_memory" . ]]
      }
    }
  }

  # ─── Postgres ─────────────────────────────────────────────────
  group "db" {
    count = 1

    network {
      port "db" {
        static = [[ var "db_port" . ]]
        to     = 5432
      }
    }

    service {
      name     = "db"
      port     = "db"
      provider = "nomad"
    }

    task "db" {
      driver = "docker"

      config {
        image = "postgres:15-alpine"
        ports = ["db"]
      }

      env {
        POSTGRES_USER     = [[ var "postgres_user" . | quote ]]
        POSTGRES_PASSWORD = [[ var "postgres_password" . | quote ]]
      }

      resources {
        cpu    = [[ var "resources.db_cpu" . ]]
        memory = [[ var "resources.db_memory" . ]]
      }
    }
  }

  # ─── Vote (Python web UI) ────────────────────────────────────
  group "vote" {
    count = [[ var "vote_count" . ]]

    network {
      port "http" {
        to = 80
      }
    }

    service {
      name     = "vote"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.vote.rule=Host(`vote.localhost`)",
        "traefik.http.routers.vote.entrypoints=web",
      ]
    }

    task "vote" {
      driver = "docker"

      config {
        image = "dockersamples/examplevotingapp_vote"
        ports = ["http"]
        extra_hosts = ["redis:host-gateway"]
      }

      resources {
        cpu    = [[ var "resources.vote_cpu" . ]]
        memory = [[ var "resources.vote_memory" . ]]
      }
    }
  }

  # ─── Result (Node.js web UI) ─────────────────────────────────
  group "result" {
    count = [[ var "result_count" . ]]

    network {
      port "http" {
        to = 80
      }
    }

    service {
      name     = "result"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.result.rule=Host(`result.localhost`)",
        "traefik.http.routers.result.entrypoints=web",
      ]
    }

    task "result" {
      driver = "docker"

      config {
        image = "dockersamples/examplevotingapp_result"
        ports = ["http"]
        extra_hosts = ["db:host-gateway"]
      }

      resources {
        cpu    = [[ var "resources.result_cpu" . ]]
        memory = [[ var "resources.result_memory" . ]]
      }
    }
  }

  # ─── Worker (.NET background processor) ──────────────────────
  group "worker" {
    count = 1

    network {
      mode = "host"
    }

    task "worker" {
      driver = "docker"

      config {
        image        = "dockersamples/examplevotingapp_worker"
        network_mode = "host"
        extra_hosts  = ["redis:host-gateway", "db:host-gateway"]
      }

      env {
        REDIS    = "127.0.0.1:[[ var "redis_port" . ]]"
        POSTGRES = "host=127.0.0.1 port=[[ var "db_port" . ]] user=[[ var "postgres_user" . ]] password=[[ var "postgres_password" . ]] dbname=postgres sslmode=disable"
      }

      resources {
        cpu    = [[ var "resources.worker_cpu" . ]]
        memory = [[ var "resources.worker_memory" . ]]
      }
    }
  }
}
