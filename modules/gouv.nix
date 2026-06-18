# Gouv identity — government persona.
# Declares sops secrets for PII and generates includable git config fragments.
# Does NOT enable or configure git itself.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.identities.gouv;

  gitIni = pkgs.formats.gitIni { };
in
{
  options.identities.gouv = {
    enable = mkEnableOption "the gouv identity";

    git = {
      enable = mkEnableOption "git identity includes for gouv" // {
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
      defaultSopsFile = ./../secrets/gouv.enc.yaml;
      defaultSopsFormat = "yaml";

      secrets = {
        gouv-email = { };
        gouv-gpg-key = { };
        gouv-name = { };
      };

      templates = {
        gouv-git-config = {
          file = gitIni.generate "config" {
            gpg.format = cfg.git.gpgFormat;
            user = {
              email = config.sops.placeholder.gouv-email;
              name = config.sops.placeholder.gouv-name;
              signingkey = config.sops.placeholder.gouv-gpg-key;
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
            path = config.lib.file.mkOutOfStoreSymlink config.sops.templates.gouv-git-config.path;
          };
        in
        if cfg.git.gitpath != null
        then baseEntry // { condition = "gitpath:${cfg.git.gitpath}"; }
        else baseEntry
      )
    ];
  };
}
