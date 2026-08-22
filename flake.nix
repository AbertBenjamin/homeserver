{
  description = "Verktøy for å jobbe med homeserver-repoet lokalt";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin" # Apple Silicon
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          # terraform er BSL-lisensiert (ikke-fri) siden v1.6 — trygt å tillate
          # for egen bruk, det er kun SaaS-konkurrenter til HashiCorp lisensen
          # retter seg mot.
          config.allowUnfree = true;
        };
    in
    {
      devShells = forEachSystem (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              terraform # samme binær CI bruker (hashicorp/setup-terraform), ikke opentofu
              sops
              libvirt # gir virsh-klienten mot qemu+ssh://-hosten (ren klient, ingen lokal virtualisering nødvendig)
            ];
          };
        }
      );
    };
}
