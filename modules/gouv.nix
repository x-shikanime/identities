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
            commit.gpgsign = true;
            gpg.format = "ssh";

            user = {
              email = config.sops.placeholder.gouv-email;
              name = config.sops.placeholder.gouv-name;
              signingkey = config.sops.placeholder.gouv-gpg-key;
            };
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
