# Docker Swarm learning lab

A throwaway 3-"node" Swarm cluster you can spin up on this same machine to
practice Swarm commands. It is **not** a production pattern and is kept
fully separate from the real stack in `../../compose.yml` — nothing here
is wired into `.github/workflows/workflow.yml`.

Why this exists: on a single physical host, Swarm's actual value
proposition (scheduling across independently-failing hardware) doesn't
apply. This lab lets you learn the mechanics anyway, without pretending
it gives you real redundancy — see the warning in `docker-compose.lab.yml`.

## Start the lab

```bash
cd learning/swarm-lab
docker compose -f docker-compose.lab.yml up -d
```

This starts three `docker:dind` containers (`swarmlab-manager`,
`swarmlab-worker1`, `swarmlab-worker2`), each running its own isolated
Docker daemon, connected on a private `swarmlab` network.

## Form the cluster

```bash
MANAGER_IP=$(docker exec swarmlab-manager hostname -i)

docker exec swarmlab-manager docker swarm init --advertise-addr "$MANAGER_IP"

JOIN_TOKEN=$(docker exec swarmlab-manager docker swarm join-token -q worker)

docker exec swarmlab-worker1 docker swarm join --token "$JOIN_TOKEN" "$MANAGER_IP:2377"
docker exec swarmlab-worker2 docker swarm join --token "$JOIN_TOKEN" "$MANAGER_IP:2377"

docker exec swarmlab-manager docker node ls
```

## Deploy the example stack

```bash
docker cp lab-stack.yml swarmlab-manager:/lab-stack.yml
docker exec swarmlab-manager docker stack deploy -c /lab-stack.yml labstack

docker exec swarmlab-manager docker service ls
docker exec swarmlab-manager docker service ps labstack_web
```

Visit `http://localhost:8888` on the host — the manager's published port
is reachable directly since it's just another container on this machine.

## Things worth practicing

```bash
# Scale a service
docker exec swarmlab-manager docker service scale labstack_web=5

# Rolling update (watch it go one replica at a time per update_config)
docker exec swarmlab-manager docker service update --force labstack_web

# Drain a node and watch its tasks migrate
docker exec swarmlab-manager docker node update --availability drain worker1
docker exec swarmlab-manager docker service ps labstack_web

# Bring it back
docker exec swarmlab-manager docker node update --availability active worker1
```

Also worth noticing hands-on: try adding `network_mode: "service:x"`,
`cap_add`, or `devices` to `lab-stack.yml` and run `docker stack deploy`
again — Swarm silently ignores all three. That's the exact reason the
real stack in this repo (pihole, wireguard, gluetun, qbittorrent,
fail2ban) can't move to Swarm as-is.

## Tear down

```bash
docker exec swarmlab-manager docker stack rm labstack
docker compose -f docker-compose.lab.yml down -v
```

## Want to try Kubernetes instead?

See `../k3d-lab/README.md` for an equally disposable k3d-based cluster —
useful for comparing how the same "VPN sidecar" / "rolling update" /
"drain a node" concepts are expressed there.
