# Operator 6O identity — YoRHa operator persona.
# Declares sops secrets for PII and generates includable git config fragments.
# Does NOT enable or configure git itself.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.identities.operator-6o;

  gitIni = pkgs.formats.gitIni { };
in
{
  options.identities.operator-6o = {
    enable = mkEnableOption "the operator-6o identity";

    git = {
      enable = mkEnableOption "git identity includes for operator-6o" // {
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
        default = "gpg";
        description = "GPG format for signing.";
      };
    };
  };

  config = mkIf cfg.enable {
    sops = {
      age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      defaultSopsFile = ./../secrets/operator6o.enc.yaml;
      defaultSopsFormat = "yaml";

      secrets = {
        operator6o-email = { };
        operator6o-gpg-key = { };
        operator6o-name = { };
      };

      templates = {
        operator6o-git-config = {
          file = gitIni.generate "config" {
            gpg.format = cfg.git.gpgFormat;
            user = {
              email = config.sops.placeholder.operator6o-email;
              name = config.sops.placeholder.operator6o-name;
              signingkey = config.sops.placeholder.operator6o-gpg-key;
            };
          } // optionalAttrs cfg.git.signByDefault {
            commit.gpgsign = true;
          };
          mode = "0644";
        };
      };
    };

    identities.git.includes = mkIf cfg.git.enable [
      (
        let
          baseEntry = {
            path = config.lib.file.mkOutOfStoreSymlink config.sops.templates.operator6o-git-config.path;
          };
        in
        if cfg.git.gitpath != null
        then baseEntry // { condition = "gitpath:${cfg.git.gitpath}"; }
        else baseEntry
      )
    ];
  };
}
