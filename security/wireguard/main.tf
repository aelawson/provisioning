variable "count" {}

variable "connections" {
  type = "list"
}

variable "private_ips" {
  type = "list"
}

variable "vpn_interface" {
  type = "string"
}

variable "vpn_port" {
  type = "string"
}

variable "hostnames" {
  type = "list"
}

variable "overlay_cidr" {
  type = "string"
}

variable "vpn_iprange" {
  default = "10.0.1.0/24"
}

resource "null_resource" "wireguard" {
  count = "${var.count}"

  triggers {
    count = "${var.count}"
  }

  connection {
    host = "${element(var.connections, count.index)}"
    user = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get install -yq linux-headers-$(uname -r)",
      "apt-get install -yq software-properties-common python-software-properties build-essential",
      "add-apt-repository -y ppa:wireguard/wireguard",
      "apt-get update",
      "apt-get install -yyq wireguard-dkms wireguard-tools"
    ]
  }

  provisioner "remote-exec" {
    inline = {
      "${join("\n", formatlist("echo '%s %s' >> /etc/hosts", data.template_file.vpn_ips.*.rendered, var.hostnames))}",
    }
  }

  provisioner "file" {
    content =
    destination = "/etc/wireguard/${var.vpn_interface}.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /etc/wireguard/${var.vpn_interface}.conf",
      "systemctl is-enabled wg-quick@${var.vpn_interface} || systemctl enable wg-quick@${var.vpn_interface}",
      "systemctl restart wg-quick@${var.vpn_interface}"
    ]
  }

  provisioner "file" {
    content = "${element(data.template_file.overlay_route_service.*.rendered, count.index)}"
    destination = "/etc/systemd/system/overlay_route_service.service"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl start overlay_route_service.service",
      "systemctl is-enabled overlay_route_service.service || systemctl enable overlay_route_service.service"
    ]
  }

  data "template_file" "interface_conf" {
    count = "${var.count}"
    template = "${file("${path.module}/templates/interface.conf")}"

    vars {
      address = "${element(data.template_file.vpn_ips.*.rendered, count.index)}"
      port = "${var.vpn_port}"
      private_key = "${element(data.template_file.keys.*.result.private_key, count.index)}"
      peers = "${replace(join("\n", data.template_file.peer_conf.*.rendered), element(data.template_file.peer_conf.*.rendered, count.index), "")}"
    }
  }

  data "template_file" "peer_conf" {
    count = "${var.count}"
    template = "${file("${path.module}/templates/peer.conf")}"

    vars {
      endpoint = "${element(var.private_ips, count.index)}"
      port = "${var.vpn_port}"
      public_key = "${element(data.template_file.keys.*.result.public_key, count.index)}"
      allowed_ips = "${element(data.template_file.vpn_ips.*.rendered, count.index)}"
    }
  }

  data "template_file" "overlay_route_service" {
    count = "${var.count}"
    template = "${file("${path.module}/templates/overlay_route_service.service")}"

    vars {
      address = "${element(data.template_file.vpn_ips.*.rendered, count.index)}"
      overlay_cidr = "${var.overlay_cidr}"
    }
  }

  data "template_file" "vpn_ips" {
    count = "${var.count}"
    template = "$${ip}"

    vars = {
      ip = "${cidrhost(var.vpn_iprange, count.index + 1)}"
    }
  }

  data "external" "keys" {
    count = "${var.count"
    program = ["sh", "${path.module}/scripts/keys.sh"]
  }

  output "vpn_ips" {
    depends_on = ["null_resource.wireguard"]
    value = ["${data.template_file.vpn_ips.*.rendered}"]
  }

  output "vpn_port" {
    value = "${var.vpn_port}"
  }

  output "vpn_unit" {
    value = "wg-quick@${var.vpn_interface}.service"
  }

  output "overlay_cidr" {
    value = "${var.overlay_cidr}"
  }
}