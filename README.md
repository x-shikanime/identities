# shikanime/identities

Nix flake modules for managing personas. The modules focus on identity data and
emit the smallest useful fragments for tools they support, without enabling the
whole tool configuration.

SSH signing is enforced by the identity modules themselves. `extraConfig` is
only for non-signing Git settings.

## Identities

| Identity     | Name                 | Email                                         | Signing |
| ------------ | -------------------- | --------------------------------------------- | ------- |
| `shikanime`  | Shikanime Deva       | `william.phetsinorath@shikanime.studio`       | SSH     |
| `gouv`       | William Phetsinorath | `william.phetsinorath-open@interieur.gouv.fr` | SSH     |
| `operator6o` | Operator 6O          | `operator6o@shikanime.studio`                 | SSH     |

## Quick Start

```nix
{
  inputs.identities.url = "github:shikanime/identities";

  outputs = { self, identities, nixpkgs, home-manager, sops-nix, ... }: {
    # NixOS
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        identities.nixosModules.identities
        { identities.shikanime.enable = true; }
      ];
    };

    # home-manager
    homeConfigurations.user = home-manager.lib.homeConfiguration {
      modules = [
        sops-nix.homeModules.default
        identities.homeModules.default

        {
          identities = {
            shikanime.enable = true;
            gouv = {
              enable = true;
              git.condition = "gitpath:/home/shika/Source/Repos/github.com/cloud-pi-native";
              jj.extraConfig."--when.repositories" = [
                "/home/shika/Source/Repos/github.com/cloud-pi-native"
              ];
            };
            "operator-6o" = {
              enable = true;
              git.condition = "gitpath:/home/shika/Source/Repos/github.com/operator6o";
              jj.extraConfig."--when.repositories" = [
                "/home/shika/Source/Repos/github.com/operator6o"
              ];
            };
          };
        }
      ];
    };
  };
}
```

## Development

```bash
direnv allow   # or: nix develop
nix fmt        # format all files
nix flake check
```

See `AGENTS.md` for module options and coding standards.
