output "nodes" {
  description = "k3s-noder med rolle og IP — input til k3s-repoet"
  value = {
    for name, node in var.nodes : name => {
      role = node.role
      ip   = node.ip
    }
  }
}

output "ssh_commands" {
  description = "SSH via Debian-hosten (VM-ene ligger bak NAT)"
  value = {
    for name, node in var.nodes :
    name => "ssh -J ${var.admin_user}@<debian-host> ${var.admin_user}@${node.ip}"
  }
}
