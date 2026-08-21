# Fysisk host

- `preseed.cfg` — uovervåket Debian-installasjon (OS + SSH-nøkkel, engangs)
- `bootstrap.sh` — alt oppå OS-et (docker, libvirt, sops, grupper). Idempotent — kjør på nytt ved endringer.

## Reinstallasjon

```sh
# 1. Serve preseed fra arbeidsstasjonen
cd host && python3 -m http.server 8000

# 2. Boot serveren fra Debian 13 netinst-USB, trykk `e` i bootmenyen,
#    legg til på kernel-linjen:
#      auto=true priority=critical preseed/url=http://<workstation-ip>:8000/preseed.cfg

# 3. Etter reboot
scp host/bootstrap.sh debian@192.168.1.39:
ssh debian@192.168.1.39 sudo ./bootstrap.sh

# 4. Manuelle steg (scriptet skriver dem ut):
#    - gjenopprett age-nøkkel fra backup -> ~/.config/sops/age/keys.txt
#    - registrer GitHub-runner (Settings -> Actions -> Runners)
# 5. push til main -> CI deployer compose + terraform
```

Backup av `~/.config/sops/age/keys.txt` må finnes utenfor serveren.
`preseed.cfg` er utestet til den brukes — test evt. mot en engangs-VM først.
