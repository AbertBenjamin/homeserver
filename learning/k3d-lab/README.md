# Kubernetes (k3d) learning lab

A disposable single/multi-node Kubernetes cluster, running as containers
on this same machine via [k3d](https://k3d.io/) (k3s inside Docker). Like
`../swarm-lab`, this is purely for learning — it is not wired into the
production stack (`../../compose.yml`) or the deploy workflow, and gives
no real multi-host redundancy since everything still runs on one machine.

Why k3d instead of raw `kubeadm` or DinD nodes: it's the standard,
lightweight way homelab folks learn Kubernetes locally — one binary, no
VM required, and it maps directly onto real k3s if you ever do add a
second physical/VM node later.

## Prerequisites

```bash
# k3d itself (wraps docker to create the cluster)
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# kubectl, to talk to it
# (skip if already installed)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/
```

## Start the lab

```bash
# 1 server (control-plane) + 2 agents (workers), isolated network
k3d cluster create swarmlab-k8s --servers 1 --agents 2 -p "8888:80@loadbalancer"

kubectl get nodes
```

## Deploy the equivalent example workload

```bash
kubectl create deployment web --image=nginxdemos/hello --replicas=3
kubectl expose deployment web --port=80 --type=ClusterIP

kubectl get pods -o wide
kubectl rollout status deployment/web
```

To actually reach it at `http://localhost:8888`, add an Ingress (k3d
ships Traefik by default):

```bash
kubectl create ingress web --class=traefik --rule="localhost/*=web:80"
```

## Things worth practicing (same concepts as the Swarm lab)

```bash
# Scale
kubectl scale deployment/web --replicas=5

# Rolling update
kubectl set image deployment/web hello=nginxdemos/hello:plain-text
kubectl rollout status deployment/web
kubectl rollout undo deployment/web

# Drain a node and watch pods reschedule
kubectl drain k3d-swarmlab-k8s-agent-0 --ignore-daemonsets --delete-emptydir-data
kubectl get pods -o wide
kubectl uncordon k3d-swarmlab-k8s-agent-0
```

## Where this repo's stack maps better onto k8s than Swarm

Worth knowing conceptually even if you don't migrate: the homelab k8s
community (e.g. the k8s-at-home / TrueCharts Helm chart ecosystem) has
well-trodden patterns for exactly this repo's hard cases that Swarm has
no answer for — a VPN sidecar container sharing qbittorrent's network
namespace via a Pod (not `network_mode: service:`), SOPS-encrypted secrets
applied declaratively via `ksops`/`kustomize` instead of decrypting `.env`
files in CI, and GPU device plugins for Jellyfin transcoding. It's a much
bigger rewrite (every service becomes a Deployment/Service/PVC manifest),
but the individual problems are solved problems in that ecosystem.

## Tear down

```bash
k3d cluster delete swarmlab-k8s
```
