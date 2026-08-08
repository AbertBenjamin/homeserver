debian home server

## Learning labs

`learning/swarm-lab` and `learning/k3d-lab` spin up disposable, single-host
Docker Swarm / Kubernetes clusters purely for practicing orchestration
commands. They are intentionally isolated from the production stack above
(`compose.yml` + `.github/workflows/workflow.yml`) — this server stays on
plain `docker compose` since it runs on one physical machine and several
services here (pihole, wireguard, gluetun, qbittorrent, fail2ban) rely on
`network_mode`, `cap_add`, and `devices`, which Swarm's `docker stack
deploy` silently drops. See each lab's README for why and for the
step-by-step.
