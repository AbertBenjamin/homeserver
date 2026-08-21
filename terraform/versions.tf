terraform {
  required_version = ">= 1.5.0"

  # State ligger på en fast sti på Debian-hosten, utenfor repo-checkouten —
  # CI-workflowen sjekker ut med clean:true og ville ellers slettet den.
  backend "local" {
    path = "/var/lib/terraform/homeserver/k3s.tfstate"
  }

  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      # 0.9.x er en full omskriving med nytt skjema — hold oss på 0.8-linjen
      version = "~> 0.8.1"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}
