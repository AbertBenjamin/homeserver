resource "libvirt_pool" "k3s" {
  name = "k3s"
  type = "dir"

  target {
    path = var.pool_path
  }
}

resource "libvirt_volume" "base" {
  name   = "debian-13-base.qcow2"
  pool   = libvirt_pool.k3s.name
  source = var.base_image_url
  format = "qcow2"
}

resource "libvirt_volume" "root" {
  for_each = var.nodes

  name           = "${each.key}-root.qcow2"
  pool           = libvirt_pool.k3s.name
  base_volume_id = libvirt_volume.base.id
  size           = each.value.disk * 1024 * 1024 * 1024
  format         = "qcow2"
}
