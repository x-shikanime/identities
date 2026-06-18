{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.identities.gouv;
  gitIni = pkgs.formats.gitIni { };
  toml = pkgs.formats.toml { };
in
{
  imports = [
    ./identities.nix
  ];

  options.identities.gouv = {
    enable = mkEnableOption "the gouv identity" // {
      default = false;
    };

    git = {
      enable = mkEnableOption "git identity includes for gouv" // {
        default = config.identities.git.enable;
      };

      condition = mkOption {
        default = null;
        description = ''
          Optional git include condition, such as `gitpath:<path>`.
        '';
        type = types.nullOr types.str;
      };

      extraConfig = mkOption {
        default = { };
        description = ''
          Extra git config merged into the generated identity include.
          Signing settings are fixed by this module and cannot be overridden.
        '';
        type = types.attrs;
      };
    };

    jj = {
      enable = mkEnableOption "Jujutsu identity config for gouv" // {
        default = config.identities.jj.enable;
      };

      extraConfig = mkOption {
        default = { };
        description = ''
          Extra Jujutsu config merged into the generated identity include.
          Signing settings are fixed by this module and cannot be overridden.
        '';
        type = types.attrs;
      };
    };

    sapling.enable = mkEnableOption "sapling identity config for gouv" // {
      default = config.identities.sapling.enable;
    };
  };

  config = mkIf cfg.enable {
    sops = {
      secrets = {
        gouv-email.sopsFile = ./../secrets/gouv.enc.yaml;
        gouv-name.sopsFile = ./../secrets/gouv.enc.yaml;
        gouv-ssh-signing-key.sopsFile = ./../secrets/gouv.enc.yaml;
      };

      templates = {
        gouv-git-config = {
          file = gitIni.generate "config" (mkMerge [
            cfg.git.extraConfig
            {
              user = {
                email = config.sops.placeholder.gouv-email;
                name = config.sops.placeholder.gouv-name;
                signingkey = config.sops.placeholder.gouv-ssh-signing-key;
              };
              commit.gpgsign = true;
              gpg.format = "ssh";
            }
          ]);
        };

        gouv-jj-config = {
          file = toml.generate "config.toml" (mkMerge [
            cfg.jj.extraConfig
            {
              signing = {
                backend = "ssh";
                behavior = mkDefault "own";
                key = config.sops.placeholder.gouv-ssh-signing-key;
              };
              user = {
                email = config.sops.placeholder.gouv-email;
                name = config.sops.placeholder.gouv-name;
              };
            }
          ]);
        };

        gouv-sapling-include = {
          content = ''
            [ui]
            username = ${config.sops.placeholder.gouv-name} <${config.sops.placeholder.gouv-email}>

            [commit]
            gpgsign = true

            %include ${
              if pkgs.stdenv.isDarwin then
                "${config.home.homeDirectory}/Library/Preferences/sapling/sapling.conf"
              else
                "${config.xdg.configHome}/sapling/sapling.conf"
            }
          '';
        };
      };
    };

    programs.git.includes = mkIf cfg.git.enable [
      (
        {
          path = config.lib.file.mkOutOfStoreSymlink config.sops.templates.gouv-git-config.path;
        }
        // optionalAttrs (cfg.git.condition != null) { condition = cfg.git.condition; }
      )
    ];

    xdg.configFile."jj/conf.d/gouv.conf" = mkIf cfg.jj.enable {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.gouv-jj-config.path;
    };

    home.file."Library/Preferences/sapling/gouv.conf" = mkIf pkgs.stdenv.isDarwin {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.gouv-sapling-include.path;
    };

    xdg.configFile."sapling/gouv.conf" = mkIf (!pkgs.stdenv.isDarwin) {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.gouv-sapling-include.path;
    };
  };
}
