variable "token" {
  type = "string"
}

variable "hosts" {
  default = 3
}

variable "ssh_keys" {
  type = "list"
}

variable "hostname_format" {
  type = "string"
}

variable "region" {
  type    = "string"
  default = "nyc1"
}

variable "image" {
  type    = "string"
  default = "ubuntu-16-04-x64"
}

variable "size" {
  type    = "string"
  default = "1gb"
}

provider "digitalocean" {
  token = "${var.token}"
}

resource "digitalocean_droplet" "host" {
  name = "${format(var.hostname_format, count.index + 1)}"
  region = "${var.region}"
  image = "${var.image}"
  size =  "${var.size}"
  ssh_keys = "${var.ssh_keys}"
  count = "${var.hosts}"
  backups = false
  private_networking = true

  count = "${var.hosts}"
}

output "hostnames" {
  value = [
    "${digitalocean_droplet.host.*.name}"
  ]
}

output "public_ips" {
  value = [
    "${digitalocean_droplet.host.*.ipv4_address}"
  ]
}

output "private_ips" {
  value = [
    "${digitalocean_droplet.host.*.ipv4_address_private}"
  ]
}

output "private_network_interface" {
  value = "eth1"
}