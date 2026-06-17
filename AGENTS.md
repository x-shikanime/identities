# Identities

Identity information and personal/system configurations managed with Nix and
Home Manager across multiple hosts. Centralizes user profiles, machine-specific
settings, and SOPS-encrypted secrets.

**Language:** Nix

## Structure

- `flake.nix` — Flake exposing host configurations and shared modules
- `hosts/` — Per-host identity and system configuration
- `secrets/` — SOPS-encrypted secrets (never commit plaintext)

## Commit Style

- Plain-text capitalized title, no conventional-commit prefix
- Body with labels: `Design:`, `Related:`, `Closes #`
- Keep Markdown lines wrapped at 80 columns and run `nix fmt` before shipping

## Stack

- 1 commit == 1 PR via ghstack (1 commit is 1 logical atomic change)
- The commit title **is** the PR title; the commit body **is** the PR body
- Split work into stacked PRs to keep each PR small and reviewable
- To pull down an existing stack: `ghstack checkout <PR_NUMBER>`
- To update a PR: edit files, then `jj squash` (or `git commit --amend`) into the
  **target commit** of the stack — the one that PR represents; the commit message
  updates the PR title and body automatically when resubmitted
- Resubmit with `ghstack` after squashing
- `ghstack land` on the head PR to land the entire stack
- Never `gh pr merge` (creates poisoned commits)
- Never force-push ghstack branches


 `main`

- Require 1 approving review
- Require linear history (no merge commits)
- Require signed commits
- Squash+rebase merge only

## Secrets

- All secrets managed via SOPS — decrypt with `sops` before editing,
  re-encrypt after
- Never commit plaintext secrets

*Always use worktrees when making changes. Test with `nix flake check` before
submitting.*
