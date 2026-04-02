# Voting App Nomad Pack

This pack deploys the [Docker Example Voting App](https://github.com/dockersamples/example-voting-app) on Nomad.

## Architecture

```
User → Vote UI (:8080) → Redis → Worker → Postgres → Result UI (:8081) → User
```

## Services

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| vote | dockersamples/examplevotingapp_vote | 8080 | Python web UI for casting votes |
| result | dockersamples/examplevotingapp_result | 8081 | Node.js web UI showing results |
| worker | dockersamples/examplevotingapp_worker | - | .NET processor: reads Redis, writes Postgres |
| redis | redis:alpine | 6379 | Message queue for votes |
| db | postgres:15-alpine | 5432 | Persistent storage for results |

## Usage

```bash
nomad-pack run voting_app --registry=local -f vars.hcl
```
