# k3s-VM-er (KVM/libvirt)

Provisjonerer 3 VM-er for k3s på Debian-hosten: `k3s-server-1` (192.168.100.11),
`k3s-agent-1` (.21) og `k3s-agent-2` (.22) — 2 vCPU, 3/2/2 GiB RAM, 20 GiB disk, basert
på Debian 13 genericcloud-image med cloud-init. VM-ene ligger på et eget libvirt
NAT-nett (`192.168.100.0/24`), så hostens nettverksoppsett røres ikke.

Selve k3s-installasjonen gjøres fra eget repo; output `nodes` gir rolle + IP per node.

## Deploy

Deployes av `.github/workflows/terraform.yml` på den self-hostede runneren:
PR-er som rører `terraform/` får `plan`, push til main kjører `apply`.
State ligger på `/var/lib/terraform/homeserver/k3s.tfstate` (utenfor checkouten,
siden workflowen sjekker ut med `clean: true`).

### Forutsetninger på Debian-hosten (engangs)

```sh
sudo apt install qemu-system-x86 libvirt-daemon-system
sudo adduser <runner-bruker> libvirt   # restart runner-tjenesten etterpå
sudo install -d -o <runner-bruker> /var/lib/terraform/homeserver
```

`terraform`-binæren lastes ned av `hashicorp/setup-terraform` i workflowen.

Manuell kjøring på hosten funker også (`cd terraform && terraform init && terraform apply`)
— samme state-fil brukes, men da må brukeren din ha skrivetilgang til state-katalogen.

## Tilgang til nodene

VM-ene er bak NAT og kun nåbare fra hosten:

```sh
ssh -J debian@<debian-host> debian@192.168.100.11
```

For kubectl fra egen maskin, tunnelér API-porten:

```sh
ssh -L 6443:192.168.100.11:6443 debian@<debian-host>
```

(og pek kubeconfig mot `https://127.0.0.1:6443`; sørg for at k3s installeres med
`--tls-san` som dekker dette, f.eks. host-IP-en.)

Skal tjenester i klusteret eksponeres på LAN, gjøres det enklest via hostens
nginx/port-forward mot node-IP-ene.
