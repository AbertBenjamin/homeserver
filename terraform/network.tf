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

  # Pi-hole binder 0.0.0.0:53 på hosten, så nettets dnsmasq kan ikke selv
  # tilby DNS (port 53 på 192.168.100.1 er opptatt). DHCP deler i stedet ut
  # eksterne DNS-servere direkte, så cluster-infra ikke avhenger av Pi-hole.
  dns {
    enabled = false
  }

  dnsmasq_options {
    options {
      option_name  = "dhcp-option"
      option_value = "6,1.1.1.1,8.8.8.8"
    }
  }
}
