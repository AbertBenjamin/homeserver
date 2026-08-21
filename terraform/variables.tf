variable "libvirt_uri" {
  description = "Libvirt-URI. 'qemu:///system' når terraform kjøres på Debian-hosten, 'qemu+ssh://debian@<host>/system' ved remote kjøring."
  type        = string
  default     = "qemu:///system"
}

variable "base_image_url" {
  description = "Debian cloud-image som VM-diskene baseres på"
  type        = string
  default     = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
}

variable "pool_path" {
  description = "Katalog på hosten for VM-disker (utenfor repo-checkout)"
  type        = string
  default     = "/var/lib/libvirt/k3s"
}

variable "network_cidr" {
  description = "Subnett for libvirt NAT-nettet"
  type        = string
  default     = "192.168.100.0/24"
}

variable "admin_user" {
  description = "Brukernavn som opprettes i VM-ene"
  type        = string
  default     = "debian"
}

variable "ssh_public_key" {
  description = "Offentlig SSH-nøkkel som legges inn i VM-ene"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEE7zqr/qlkP1UvFYomfnSmyw+fhMOdV+hQwcsxmN8n5 benjamin@nixos-desktop"
}

variable "nodes" {
  description = "k3s-noder: 1 server + 2 agents"
  type = map(object({
    role   = string
    vcpu   = number
    memory = number # MiB
    disk   = number # GiB
    ip     = string
  }))
  # Nøkternt dimensjonert for 16 GB host ved siden av docker-stacken (~7 GiB totalt).
  # Skaler opp memory her ved RAM-oppgradering eller når clusteret skal kjøre noe reelt.
  default = {
    k3s-server-1 = { role = "server", vcpu = 2, memory = 3072, disk = 20, ip = "192.168.100.11" }
    k3s-agent-1  = { role = "agent", vcpu = 2, memory = 2048, disk = 20, ip = "192.168.100.21" }
    k3s-agent-2  = { role = "agent", vcpu = 2, memory = 2048, disk = 20, ip = "192.168.100.22" }
  }
}

locals {
  # Fast MAC per node (52:54:00 = QEMU-prefiks) så DHCP-reservasjonen alltid treffer
  node_macs = {
    for name, node in var.nodes :
    name => format("52:54:00:6b:33:%02x", tonumber(split(".", node.ip)[3]))
  }
}
