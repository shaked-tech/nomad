# Nomad Local Cluster

A local HashiCorp Nomad setup with 1 server and 2 clients, all running on your Mac. Includes a Traefik ingress controller and a multi-service voting app deployed via Nomad Pack.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Nomad Cluster                            │
│                                                              │
│   Server (port 4646)       ← schedules work, manages state  │
│   Client 1 (port 5656)     ← runs workloads (2 GHz, 8 GiB) │
│   Client 2 (port 6656)     ← runs workloads (2 GHz, 8 GiB) │
│                                                              │
│   Traefik (port 80)        ← ingress / reverse proxy        │
│                                                              │
│   ┌─────────────────────────────────────────────────┐        │
│   │  Voting App (Nomad Pack)                        │        │
│   │                                                 │        │
│   │  vote (:80) → Redis → Worker → Postgres         │        │
│   │                                    ↓             │        │
│   │                              result (:80)        │        │
│   └─────────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────────┘
        all on 127.0.0.1
```

## Prerequisites

- [Nomad](https://developer.hashicorp.com/nomad/install) — `brew install hashicorp/tap/nomad`
- [Nomad Pack](https://developer.hashicorp.com/nomad/docs/nomad-pack) — `brew install hashicorp/tap/nomad-pack`
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) — for running Docker-based jobs

## Quick Start

```bash
# Start the cluster
./nodes/start-cluster.sh

# Deploy infra services
nomad job run infra/traefik.nomad.hcl
nomad job run infra/nomad-ops.nomad.hcl

# Deploy the voting app
nomad-pack run apps/packs/voting_app

# Open in browser
open http://vote.localhost        # Vote UI
open http://result.localhost      # Results UI
open http://127.0.0.1:8081        # Traefik dashboard
open http://127.0.0.1:4646/ui     # Nomad UI

# Stop everything
nomad job stop voting-app
nomad job stop traefik
./nodes/stop-cluster.sh
```

## Access URLs

| Service | URL | Description |
|---------|-----|-------------|
| nomad-ops | http://nomad-ops.localhost | GitOps operator UI |
| Vote UI | http://vote.localhost | Cast votes (Cats vs Dogs) |
| Result UI | http://result.localhost | Live results dashboard |
| Traefik Dashboard | http://127.0.0.1:8081/dashboard/ | Ingress routes and services |
| Nomad UI | http://127.0.0.1:4646/ui | Cluster management |

## Project Structure

```
.
├── nodes/                          # Nomad agent config (not managed by nomad-ops)
│   ├── server.hcl                  # Nomad server config
│   ├── client1.hcl                 # Client 1 config (port 5656, 2 GHz, 8 GiB)
│   ├── client2.hcl                 # Client 2 config (port 6656, 2 GHz, 8 GiB)
│   ├── start-cluster.sh            # Start all agents
│   └── stop-cluster.sh             # Stop all agents
│
├── infra/                          # Infrastructure jobs (nomad-ops source)
│   ├── traefik.nomad.hcl           # Traefik ingress (file provider + nomadService)
│   └── nomad-ops.nomad.hcl         # GitOps operator (nomad-ops.github.io/nomad-ops)
│
├── apps/                           # Application workloads (nomad-ops source)
│   ├── nginx.nomad.hcl             # Simple nginx job (example)
│   ├── whoami.nomad.hcl            # Traefik whoami service (example)
│   ├── counting.nomad.hcl          # HashiCorp counting API (example)
│   ├── dashboard.nomad.hcl         # HashiCorp counter dashboard (example)
│   └── packs/
│       └── voting_app/             # Nomad Pack: Docker example-voting-app
│           ├── metadata.hcl
│           ├── variables.hcl
│           ├── TEMPLATE.md
│           └── templates/
│               └── voting_app.nomad.tpl
│
└── README.md
```

## Voting App (Nomad Pack)

Ported from [dockersamples/example-voting-app](https://github.com/dockersamples/example-voting-app). Deploys 5 services as a single Nomad job:

| Service | Image | Role |
|---------|-------|------|
| vote | `dockersamples/examplevotingapp_vote` | Python web UI for casting votes |
| result | `dockersamples/examplevotingapp_result` | Node.js web UI showing live results |
| worker | `dockersamples/examplevotingapp_worker` | .NET processor: reads Redis, writes Postgres |
| redis | `redis:alpine` | Message queue for incoming votes |
| db | `postgres:15-alpine` | Persistent storage for results |

```bash
# Deploy
nomad-pack run apps/packs/voting_app

# Deploy with custom variables
nomad-pack run apps/packs/voting_app --var vote_count=2

# Render template without deploying
nomad-pack render apps/packs/voting_app

# Stop
nomad job stop -purge voting-app
```

## Traefik Ingress

Traefik runs as a Nomad `service` job and routes traffic via host-based rules. It uses Nomad's **template stanza** with `nomadService` to auto-discover backends and rewrite addresses for Docker-for-Mac compatibility (`host.docker.internal`).

```
Browser → vote.localhost:80   → Traefik → vote (dynamic port)
Browser → result.localhost:80 → Traefik → result (dynamic port)
```

The dynamic config regenerates automatically when services change (new deploys, scaling, etc).

## Useful Commands

```bash
# Cluster
nomad server members          # List servers
nomad node status             # List clients

# Jobs
nomad job status              # List all jobs
nomad job status <job>        # Job details
nomad job allocs <job>        # Show allocations
nomad job run <file>          # Deploy a job
nomad job plan <file>         # Dry-run a job change
nomad job stop <job>          # Stop a job
nomad job stop -purge <job>   # Stop and remove a job

# Debugging
nomad alloc status <alloc-id>   # Allocation details
nomad alloc logs <alloc-id>     # View stdout logs
nomad alloc logs -stderr <id>   # View stderr logs
nomad alloc exec <id> <cmd>     # Exec into allocation

# Nomad Pack
nomad-pack registry list                  # List registries
nomad-pack run <pack-path>                # Deploy a pack
nomad-pack render <pack-path>             # Preview rendered template
nomad-pack run <pack> --var key=value     # Deploy with variables
```

## Data Directories

All data is stored under `/tmp/nomad/` and cleaned on each `start-cluster.sh` run:

```
/tmp/nomad/
├── server/
├── client1/
└── client2/
```

## Notes

- Docker Desktop must be running before starting the cluster
- `*.localhost` resolves to `127.0.0.1` on macOS — no `/etc/hosts` edits needed
- Cloud fingerprinters (AWS, GCE, Azure) are disabled via `fingerprint.denylist` in client configs
- Each client is configured with `cpu_total_compute = 2000` and `memory_total_mb = 8192` to override incorrect fingerprinting when multiple clients share one host
- This setup is for **local development only** — not suitable for production
