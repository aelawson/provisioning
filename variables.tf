/* Providers */

/* Digital Ocean */

variable "digitalocean_token" {
  default = ""
}

variable "digitalocean_ssh_keys" {
  default = []
}

variable "digitalocean_region" {
  default = "nyc1"
}

/* General */

variable "hosts" {
  default = 3
}

variable "hostname_format" {
  default = "kubernetes-%d"
}