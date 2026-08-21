# NAT-nett med DHCP der hver node får fast IP via statisk lease (MAC-bundet).
# Rører ikke hostens fysiske nettverksoppsett.
resource "libvirt_network" "k3s" {
  name      = "k3s"
  mode      = "nat"
  domain    = "k3s.internal"
  addresses = [var.network_cidr]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled    = true
    local_only = true
  }
}
