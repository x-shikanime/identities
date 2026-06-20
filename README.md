<!-- markdownlint-disable first-line-heading -->

![header.png](https://raw.githubusercontent.com/shikanime/shikanime/main/assets/github-header.png)

<!-- markdownlint-enable first-line-heading -->

# Identities

These modules keep my identity data in one place and only emit the small config
fragments that each tool needs.

They do not enable `git`, `jj`, or `sl` for you. They only write identity
snippets, so you can drop them into an existing Home Manager setup without
pulling in a full tool configuration.

## What It Gives You

- `git` includes with fixed SSH signing
- `jj` config fragments with SSH signing
- `sapling` config fragments with the right user and signing data
- SOPS-backed secrets for names, emails, and signing keys

## Quick Start

Import the shared module once, then enable the identities you want:

```nix
{
  inputs.identities.url = "github:shikanime/identities";
  inputs.sops-nix.url = "github:mic92/sops-nix";

  outputs = { home-manager, identities, sops-nix, ... }: {
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

## Option Shape

The design is intentionally small:

- `identities.enable` turns on the identity system
- `identities.git.enable`, `identities.jj.enable`, and
  `identities.sapling.enable` control the global defaults
- `identities.ghstack.enable` and `identities.glab.enable` control the global
  defaults for `shikanime` ghstack and glab config
- `identities.<name>.enable` turns a specific identity on or off
- `identities.<name>.git.enable`, `.jj.enable`, and `.sapling.enable` control
  that identity’s tool output
- `identities.shikanime.ghstack.enable` and `.glab.enable` control whether those
  config fragments are emitted for `shikanime`
- `identities.<name>.git.extraConfig` merges into the generated Git include
- `identities.<name>.git.condition` sets the Git include condition
- `identities.<name>.jj.extraConfig` merges into the generated JJ config
- `identities.<name>.sapling.extraConfig` merges into the generated Sapling
  config
- `identities.shikanime.ghstack.extraConfig` merges into the generated
  `ghstackrc`
- `identities.shikanime.glab.extraConfig` merges into the generated glab config

SSH signing is fixed in the modules. `extraConfig` is only for the remaining
tool settings.

## Generated Files

- `shikanime`
  - `jj/conf.d/shikanime.toml`
  - `sapling/shikanime/sapling.conf`
- `gouv`
  - `jj/conf.d/gouv.toml`
  - `sapling/gouv/sapling.conf`
- `operator-6o`
  - `jj/conf.d/operator6o.toml`
  - `sapling/operator6o/sapling.conf`

Git identity snippets are written through `programs.git.includes`.

## Secrets

The encrypted values live in:

- `secrets/shikanime.enc.yaml`
- `secrets/gouv.enc.yaml`
- `secrets/operator6o.enc.yaml`

The repo ships a SOPS-enabled dev shell. Edit secrets in the `identities`
repository with:

```bash
sops secrets/<name>.enc.yaml
```

## Development

```bash
direnv allow   # or: nix develop
nix fmt
nix flake check
```

## Notes

- The modules are meant to be composable.
- They only emit identity fragments.
- If you enable multiple identities, each one stays isolated by its own
  `git.condition`, JJ repository scoping, and Sapling wrapper file.

See `AGENTS.md` for the full module contract and coding conventions.
