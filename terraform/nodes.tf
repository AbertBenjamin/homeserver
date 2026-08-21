resource "libvirt_cloudinit_disk" "node" {
  for_each = var.nodes

  name = "${each.key}-cloudinit.iso"
  pool = libvirt_pool.k3s.name

  user_data = templatefile("${path.module}/templates/user-data.yaml.tftpl", {
    hostname   = each.key
    admin_user = var.admin_user
    ssh_key    = var.ssh_public_key
  })
}

resource "libvirt_domain" "node" {
  for_each = var.nodes

  name      = each.key
  vcpu      = each.value.vcpu
  memory    = each.value.memory
  autostart = true

  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.node[each.key].id

  network_interface {
    network_id     = libvirt_network.k3s.id
    mac            = local.node_macs[each.key]
    hostname       = each.key
    addresses      = [each.value.ip]
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.root[each.key].id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}
