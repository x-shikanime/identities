# Identities

Nix flake modules for managing personas. PII is stored in sops-encrypted secrets.
Each identity writes config files to XDG locations via `xdg.configFile`.

## Identities

- **shikanime** — Primary identity for Shikanime Studio work.
  - Config: `~/.config/git/config.d/shikanime`, `~/.config/jj/conf.d/shikanime.toml`
  - Sops secrets: `shikanime-name`, `shikanime-email`, `shikanime-gpg-key`, `shikanime-ssh-signing-key`
- **gouv** — Government identity.
  - Config: `~/.config/git/config.d/gouv`
- **operator-6o** — YoRHa operator identity.
  - Config: `~/.config/git/config.d/operator6o`

## Usage

Consumer must import both `sops-nix.homeModules.default` and `identities.homeModules.shikanime`:

```nix
{
  inputs.identities.url = "github:shikanime/identities";
  inputs.sops-nix.url = "github:mic92/sops-nix";

  outputs = { self, identities, sops-nix, home-manager, ... }: {
    homeConfigurations.user = home-manager.lib.homeConfiguration {
      modules = [
        sops-nix.homeModules.default
        identities.homeModules.shikanime
      ];
    };
  };
}
```

The identities module declares `sops.secrets` and reads PII from `config.sops.placeholder.*`.
The consumer must provide `sops-nix.homeModules.default` for the `sops` option to be available.

## File Structure

```text
modules/
├── base.nix           # Shared types
├── default.nix        # Aggregator — imports all identities
├── identities.nix     # Top-level options
├── shikanime.nix      # Primary identity (sops + config files)
├── gouv.nix           # Government identity (config file)
└── operator-6o.nix    # YoRHa operator identity (config file)

secrets/
└── identities.yaml    # Sops-encrypted PII
```

## Sops

Secrets are encrypted with age key `age1pwl9yz4k4255a4h8qz7lafce8wxhsul0cnqwmr8528fqgujlfshshv3z3g`.
Edit with: `sops secrets/identities.yaml`

## Coding Style

- Nix files: 2-space indentation, `with lib;` at top.
- Commit messages: plain-text capitalized title, no conventional-commit prefix.
- Run `nix fmt` before shipping.

## Stack

- 1 commit == 1 PR via ghstack.
- Amend + `ghstack` to resubmit.
- `ghstack land` on head PR to land the entire stack.
- Never `gh pr merge` (creates poisoned commits).
- Never force-push ghstack branches.

_Licensed under Apache-2.0._
