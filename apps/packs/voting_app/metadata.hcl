app {
  url    = "https://github.com/dockersamples/example-voting-app"
  author = "Docker Samples"
}

pack {
  name        = "voting_app"
  description = "Docker's example voting app ported to Nomad. Includes vote UI, result UI, worker, Redis, and Postgres."
  version     = "0.1.0"
}
