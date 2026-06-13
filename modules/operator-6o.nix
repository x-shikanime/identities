# Operator 6O identity — YoRHa operator persona.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.identities.operator-6o;

  gitConfig = pkgs.writeText "git-config-operator6o" ''
    [user]
      name = ${config.sops.placeholder.operator6o-name}
      email = ${config.sops.placeholder.operator6o-email}
    [commit]
      gpgsign = true
    [user]
      signingkey = ${config.sops.placeholder.operator6o-gpg-key or ""}
  '';
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
    };

    xdg.configFile."git/config.d/operator6o".source = gitConfig;
  };
}
