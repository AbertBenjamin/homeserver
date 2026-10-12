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
    sops age \
    git curl unzip vim jq

# --- vim som systemets default-editor ---------------------------------------
update-alternatives --set editor /usr/bin/vim.basic

# --- k3d ---------------------------------------------------------------------
# Installeres her (root allerede tilgjengelig), ikke ad hoc i CI — runner-
# brukeren har ikke passordløs sudo, så k3d sitt install-script (som selv
# kjører sudo internt) ville feilet der.
if ! command -v k3d >/dev/null; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# --- Grupper -----------------------------------------------------------------
adduser "$ADMIN_USER" docker

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
