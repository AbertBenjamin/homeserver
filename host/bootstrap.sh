#!/usr/bin/env bash
# Konfigurasjonslaget for den fysiske homeserveren (lag 1a).
# Kjøres etter OS-installasjon (preseed), og på nytt ved endringer — idempotent.
# Alt hosten består av utover base-OS skal være beskrevet her.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "kjør med sudo" >&2
    exit 1
fi

ADMIN_USER="${ADMIN_USER:-debian}"

# --- Docker fra offisielt apt-repo (gir 'docker compose'-pluginen) ---------
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
fi
codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${codename} stable" \
    > /etc/apt/sources.list.d/docker.list

# --- Pakker -----------------------------------------------------------------
apt-get update
apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-compose-plugin \
    qemu-system-x86 libvirt-daemon-system \
    sops age \
    git curl

# --- Grupper (docker for compose-deploy, libvirt for terraform) -------------
adduser "$ADMIN_USER" docker
adduser "$ADMIN_USER" libvirt

# --- Terraform-state: fast sti utenfor repo-checkouten ----------------------
install -d -o "$ADMIN_USER" -g "$ADMIN_USER" /var/lib/terraform/homeserver

cat <<'EOF'

Ferdig. Manuelle steg som gjenstår (secrets kan ikke bo i git):

 1. age-privatnøkkel (for sops-dekryptering i deploy-workflowen):
      gjenopprett fra backup til ~/.config/sops/age/keys.txt hos runner-brukeren

 2. GitHub Actions-runner (registreringstoken utløper etter 1 time):
      hentes fra repoet: Settings -> Actions -> Runners -> New self-hosted runner
      ./config.sh --url https://github.com/<eier>/homeserver --token <TOKEN> --labels debian
      sudo ./svc.sh install && sudo ./svc.sh start

 3. Restart runner-tjenesten hvis den kjørte fra før (nye gruppemedlemskap):
      sudo systemctl restart 'actions.runner.*'

EOF
