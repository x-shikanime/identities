# Shikanime identity — primary persona for Shikanime Studio work.
# Declares sops secrets for PII (name, email, gpg key, ssh signing key)
# and generates config fragments for git, Jujutsu, and sapling via sops templates.
# Does NOT enable or configure the tools themselves.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.identities.shikanime;

  gitIni = pkgs.formats.gitIni { };
  toml = pkgs.formats.toml { };
in
{
  options.identities.shikanime = {
    enable = mkEnableOption "the shikanime identity";

    git = {
      enable = mkEnableOption "git identity includes for shikanime" // {
        default = true;
      };

      gitpath = mkOption {
        default = null;
        description = ''
          If set, emit a conditional git include scoped to this path
          (via `condition = "gitpath:<value>"`). If null, the include
          is unconditional.
        '';
        type = types.nullOr types.str;
      };

      signByDefault = mkEnableOption "commit signing by default for this identity" // {
        default = true;
      };

      gpgFormat = mkOption {
        type = types.enum [ "ssh" "gpg" "x509" "openpgp" ];
        default = "ssh";
        description = "GPG format for signing.";
      };
    };

    jj = {
      enable = mkEnableOption "Jujutsu identity config for shikanime" // {
        default = true;
      };

      repositories = mkOption {
        default = [ ];
        description = ''
          If non-empty, scope this identity to these repository paths
          via `[--when.repositories]`. If empty, the config is global.
        '';
        type = types.listOf types.str;
      };

      signingBackend = mkOption {
        type = types.enum [ "ssh" "gpg" ];
        default = "ssh";
        description = "Signing backend for Jujutsu.";
      };

      signingBehavior = mkOption {
        type = types.enum [ "own" "force" ];
        default = "own";
        description = "Signing behavior for Jujutsu.";
      };
    };

    sapling = {
      enable = mkEnableOption "sapling identity config for shikanime" // {
        default = true;
      };
    };
  };

  config = mkIf cfg.enable {
    sops = {
      age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      defaultSopsFile = ./../secrets/shikanime.enc.yaml;
      defaultSopsFormat = "yaml";

      secrets = {
        shikanime-email = { };
        shikanime-gpg-key = { };
        shikanime-name = { };
        shikanime-ssh-signing-key = { };
      };

      templates = {
        shikanime-git-config = {
          file = gitIni.generate "config" {
            gpg.format = cfg.git.gpgFormat;
            user = {
              email = config.sops.placeholder.shikanime-email;
              name = config.sops.placeholder.shikanime-name;
              signingkey = config.sops.placeholder.shikanime-ssh-signing-key;
            };
          } // optionalAttrs cfg.git.signByDefault {
            commit.gpgsign = true;
          };
          mode = "0644";
        };

        shikanime-jj-config = {
          file = toml.generate "config.toml" {
            signing = {
              backend = cfg.jj.signingBackend;
              behavior = cfg.jj.signingBehavior;
              key = config.sops.placeholder.shikanime-ssh-signing-key;
            };
            user = {
              email = config.sops.placeholder.shikanime-email;
              name = config.sops.placeholder.shikanime-name;
            };
          } // optionalAttrs (cfg.jj.repositories != [ ]) {
            "--when.repositories" = cfg.jj.repositories;
          };
          mode = "0644";
        };

        shikanime-sapling-config = {
          file = (pkgs.formats.ini { }).generate "sapling.conf" {
            ui = {
              username = "${config.sops.placeholder.shikanime-name} <${config.sops.placeholder.shikanime-email}>";
            };
            gpg.key = config.sops.placeholder.shikanime-gpg-key;
          };
          mode = "0644";
        };
      };
    };

    identities.git.includes = mkIf cfg.git.enable [
      (
        let
          baseEntry = {
            path = config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-git-config.path;
          };
        in
        if cfg.git.gitpath != null
        then baseEntry // { condition = "gitpath:${cfg.git.gitpath}"; }
        else baseEntry
      )
    ];

    xdg.configFile."jj/conf.d/shikanime.toml" = mkIf cfg.jj.enable {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-jj-config.path;
    };

    xdg.configFile."sapling/sapling.conf" = mkIf cfg.sapling.enable {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-sapling-config.path;
    };
  };
}
