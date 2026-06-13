# Operator 6O identity — YoRHa operator persona.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.identities.operator-6o;

  gitIni = pkgs.formats.gitIni { };
in
{
  options.identities.operator-6o = {
    enable = mkEnableOption "the operator-6o identity";
  };

  config = mkIf cfg.enable {
    sops = {
      age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      defaultSopsFile = ./../secrets/identities.yaml;
      defaultSopsFormat = "yaml";
      secrets = {
        operator6o-name = { };
        operator6o-email = { };
        operator6o-gpg-key = { };
      };

      templates = {
        operator6o-git-config = {
          file = gitIni.generate "config" {
            gpg.format = "ssh";
            user = {
              name = config.sops.placeholder.operator6o-name;
              email = config.sops.placeholder.operator6o-email;
              signingkey = config.sops.placeholder.operator6o-gpg-key;
            };
            commit.gpgsign = true;
          };
          mode = "0644";
        };
      };
    };

    xdg.configFile = {
      "git/config.d/operator6o".source =
        config.lib.file.mkOutOfStoreSymlink config.sops.templates.operator6o-git-config.path;
    };
  };
}
