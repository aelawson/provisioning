terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

module "provider" {
  source          = "./provider/digitalocean"

  token           = "${var.digitalocean_token}"
  ssh_keys        = "${var.digitalocean_ssh_keys}"
  hosts           = "${var.hosts}"
  hostname_format = "${var.hostname_format}"
  region          = "${var.digitalocean_region}"
}

module "firewall" {
  source = "./security/ufw"

  count                = "${var.hosts}"
  connections          = "${module.provider.public_ips}"
  private_interface    = "${module.provider.private_network_interface}"
  vpn_interface        = "${module.wireguard.vpn_interface}"
  vpn_port             = "${module.wireguard.vpn_port}"
  kubernetes_interface = "${module.kubernetes.kubernetes_interface}"
}