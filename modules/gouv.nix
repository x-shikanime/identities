# Gouv identity — government persona.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.identities.gouv;

  gitIni = pkgs.formats.gitIni { };
in
{
  options.identities.gouv = {
    enable = mkEnableOption "the gouv identity";
  };

  config = mkIf cfg.enable {
    sops = {
      age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      defaultSopsFile = ./../secrets/identities.yaml;
      defaultSopsFormat = "yaml";
      secrets = {
        gouv-name = { };
        gouv-email = { };
        gouv-gpg-key = { };
      };

      templates = {
        gouv-git-config = {
          file = gitIni.generate "config" {
            gpg.format = "ssh";
            user = {
              name = config.sops.placeholder.gouv-name;
              email = config.sops.placeholder.gouv-email;
              signingkey = config.sops.placeholder.gouv-gpg-key;
            };
            commit.gpgsign = true;
          };
          mode = "0644";
        };
      };
    };

    xdg.configFile = {
      "git/config.d/gouv".source =
        config.lib.file.mkOutOfStoreSymlink config.sops.templates.gouv-git-config.path;
    };
  };
}
