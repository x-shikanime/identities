# Gouv identity — government persona.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.identities.gouv;

  gitConfig = pkgs.writeText "git-config-gouv" ''
    [user]
      name = ${config.sops.placeholder.gouv-name}
      email = ${config.sops.placeholder.gouv-email}
    [commit]
      gpgsign = true
    [user]
      signingkey = ${config.sops.placeholder.gouv-gpg-key or ""}
  '';
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
    };

    xdg.configFile."git/config.d/gouv".source = gitConfig;
  };
}
