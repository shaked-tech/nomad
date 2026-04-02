variable "datacenters" {
  description = "A list of datacenters in the region which are eligible for task placement."
  type        = list(string)
  default     = ["dc1"]
}

variable "vote_count" {
  description = "Number of vote frontend instances."
  type        = number
  default     = 1
}

variable "vote_port" {
  description = "Static host port for the vote UI."
  type        = number
  default     = 8080
}

variable "result_count" {
  description = "Number of result frontend instances."
  type        = number
  default     = 1
}

variable "result_port" {
  description = "Static host port for the result UI."
  type        = number
  default     = 8081
}

variable "redis_port" {
  description = "Static host port for Redis."
  type        = number
  default     = 6379
}

variable "db_port" {
  description = "Static host port for Postgres."
  type        = number
  default     = 5432
}

variable "postgres_user" {
  description = "Postgres user."
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "Postgres password."
  type        = string
  default     = "postgres"
}

variable "resources" {
  description = "Resource limits for each service."
  type = object({
    vote_cpu       = number
    vote_memory    = number
    result_cpu     = number
    result_memory  = number
    worker_cpu     = number
    worker_memory  = number
    redis_cpu      = number
    redis_memory   = number
    db_cpu         = number
    db_memory      = number
  })
  default = {
    vote_cpu       = 100
    vote_memory    = 128
    result_cpu     = 100
    result_memory  = 128
    worker_cpu     = 100
    worker_memory  = 256
    redis_cpu      = 100
    redis_memory   = 128
    db_cpu         = 100
    db_memory      = 256
  }
}
