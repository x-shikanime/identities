# Shikanime identity — primary persona for Shikanime Studio work.
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
  };

  config = mkIf cfg.enable {
    sops = {
      age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      defaultSopsFile = ./../secrets/identities.yaml;
      defaultSopsFormat = "yaml";
      secrets = {
        shikanime-name = { };
        shikanime-email = { };
        shikanime-gpg-key = { };
        shikanime-ssh-signing-key = { };
      };

      templates = {
        shikanime-git-config = {
          file = gitIni.generate "config" {
            gpg.format = "ssh";
            user = {
              name = config.sops.placeholder.shikanime-name;
              email = config.sops.placeholder.shikanime-email;
              signingkey = config.sops.placeholder.shikanime-ssh-signing-key;
            };
            commit.gpgsign = true;
          };
          mode = "0644";
        };

        shikanime-jj-config = {
          file = toml.generate "config.toml" {
            user = {
              name = config.sops.placeholder.shikanime-name;
              email = config.sops.placeholder.shikanime-email;
            };
            signing = {
              backend = "ssh";
              behavior = "own";
              key = config.sops.placeholder.shikanime-ssh-signing-key;
            };
          };
          mode = "0644";
        };
      };
    };

    xdg.configFile = {
      "git/config.d/shikanime".source =
        config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-git-config.path;
      "jj/conf.d/shikanime.toml".source =
        config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-jj-config.path;
    };
  };
}
