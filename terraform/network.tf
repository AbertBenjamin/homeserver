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

  # Forutsetter at ingenting på hosten binder 0.0.0.0:53 — derfor er Pi-hole
  # i compose.yml bundet eksplisitt til LAN-IP-en.
  dns {
    enabled    = true
    local_only = true
  }
}
