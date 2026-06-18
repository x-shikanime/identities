# Identities

Nix flake modules for managing personas. Each identity declares its own sops
secrets for PII (name, email) and, where needed, an SSH signing key, then
generates includable config fragments via sops templates.

**The identity modules do NOT enable or configure the VCS tools themselves.**
They only emit config fragments. The consumer is responsible for enabling
`programs.git`, `programs.jujutsu`, etc.

## Identities

- **shikanime** — Primary identity for Shikanime Studio work.
  - Sops secrets: `shikanime-name`, `shikanime-email`, `shikanime-gpg-key`,
    `shikanime-ssh-signing-key`
  - Sops file: `secrets/shikanime.enc.yaml`
  - Output: git includes, `jj/conf.d/shikanime.toml`, `sapling/shikanime.conf`
- **gouv** — Government identity.
  - Sops secrets: `gouv-name`, `gouv-email`, `gouv-ssh-signing-key`
  - Sops file: `secrets/gouv.enc.yaml`
  - Output: git includes (scoped via `git.condition`), `jj/conf.d/gouv.conf`,
    `sapling/gouv.conf`
- **operator-6o** — YoRHa operator identity.
  - Sops secrets: `operator6o-name`, `operator6o-email`,
    `operator6o-ssh-signing-key`
  - Sops file: `secrets/operator6o.enc.yaml`
  - Output: git includes (scoped via `git.condition`),
    `jj/conf.d/operator6o.conf`, `sapling/operator6o.conf`

## Usage

Consumer must import both `sops-nix.homeModules.default` and the identities
module:

```nix
{
  inputs.identities.url = "github:x-shikanime/identities";
  inputs.sops-nix.url = "github:mic92/sops-nix";

  outputs = { self, identities, sops-nix, home-manager, ... }: {
    homeConfigurations.user = home-manager.lib.homeConfiguration {
      modules = [
        sops-nix.homeModules.default
        identities.homeModules.default

        # Identity modules write directly to programs.git.includes
      ];
    };
  };
}
```

## Options Design

Inspired by Catppuccin/nix:

- `identities.enable` — global toggle for all identity modules
- `identities.<name>.enable` — per-identity toggle
- `identities.<name>.git.enable` / `.jj.enable` / `.sapling.enable` — per-tool
  output control
- `identities.<name>.git.extraConfig` — forwarded git config merged into the
  generated include; SSH signing fields are fixed by the module
- `identities.<name>.git.condition` — optional include condition, such as
  `gitpath:<path>`
- `identities.<name>.jj.extraConfig` — forwarded Jujutsu config merged into the
  generated include; signing fields are fixed by the module. Use
  `--when.repositories` there to scope it to repositories
- `identities.homeModules.default` — option-driven home-manager module that
  exposes `identities.shikanime.enable`, `identities.gouv.enable`, and
  `identities."operator-6o".enable`

## File Structure

```text
modules/
├── base.nix           # Shared types
├── default.nix        # Aggregator — imports all identities
├── identities.nix     # Top-level options (global toggle, git/jj/sapling)
├── shikanime.nix      # Primary identity (sops + git + jj + sapling)
├── gouv.nix           # Government identity (sops + git + jj)
└── operator-6o.nix    # YoRHa operator identity (sops + git + jj)

secrets/
├── shikanime.enc.yaml  # Sops-encrypted PII for shikanime
├── gouv.enc.yaml       # Sops-encrypted PII for gouv
└── operator6o.enc.yaml # Sops-encrypted PII for operator-6o
```

## Sops

Secrets are encrypted with age key
`age1pwl9yz4k4255a4h8qz7lafce8wxhsul0cnqwmr8528fqgujlfshshv3z3g`. Edit with:
`sops secrets/<name>.enc.yaml`

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
