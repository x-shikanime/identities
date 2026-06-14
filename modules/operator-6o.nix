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
            commit.gpgsign = true;
            gpg.format = "ssh";

            user = {
              email = config.sops.placeholder.operator6o-email;
              name = config.sops.placeholder.operator6o-name;
              signingkey = config.sops.placeholder.operator6o-gpg-key;
            };
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
