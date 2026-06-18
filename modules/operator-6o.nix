{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.identities.operator-6o;
  gitIni = pkgs.formats.gitIni { };
  toml = pkgs.formats.toml { };
in
{
  imports = [
    ./identities.nix
  ];

  options.identities.operator-6o = {
    enable = mkEnableOption "the operator-6o identity" // {
      default = false;
    };

    git = {
      enable = mkEnableOption "git identity includes for operator-6o" // {
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
      enable = mkEnableOption "Jujutsu identity config for operator-6o" // {
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

    sapling.enable = mkEnableOption "sapling identity config for operator-6o" // {
      default = config.identities.sapling.enable;
    };
  };

  config = mkIf cfg.enable {
    sops = {
      secrets = {
        operator6o-email.sopsFile = ./../secrets/operator6o.enc.yaml;
        operator6o-name.sopsFile = ./../secrets/operator6o.enc.yaml;
        operator6o-ssh-signing-key.sopsFile = ./../secrets/operator6o.enc.yaml;
      };

      templates = {
        operator6o-git-config = {
          file = gitIni.generate "config" (mkMerge [
            cfg.git.extraConfig
            {
              user = {
                email = config.sops.placeholder.operator6o-email;
                name = config.sops.placeholder.operator6o-name;
                signingkey = config.sops.placeholder.operator6o-ssh-signing-key;
              };
              commit.gpgsign = true;
              gpg.format = "ssh";
            }
          ]);
        };

        operator6o-jj-config = {
          file = toml.generate "config.toml" (mkMerge [
            cfg.jj.extraConfig
            {
              signing = {
                backend = "ssh";
                behavior = mkDefault "own";
                key = config.sops.placeholder.operator6o-ssh-signing-key;
              };
              user = {
                email = config.sops.placeholder.operator6o-email;
                name = config.sops.placeholder.operator6o-name;
              };
            }
          ]);
        };

        operator6o-sapling-include = {
          content = ''
            [ui]
            username = ${config.sops.placeholder.operator6o-name} <${config.sops.placeholder.operator6o-email}>

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
          path = config.lib.file.mkOutOfStoreSymlink config.sops.templates.operator6o-git-config.path;
        }
        // optionalAttrs (cfg.git.condition != null) { condition = cfg.git.condition; }
      )
    ];

    xdg.configFile."jj/conf.d/operator6o.conf" = mkIf cfg.jj.enable {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.operator6o-jj-config.path;
    };

    home.file."Library/Preferences/sapling/operator6o.conf" = mkIf pkgs.stdenv.isDarwin {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.operator6o-sapling-include.path;
    };

    xdg.configFile."sapling/operator6o.conf" = mkIf (!pkgs.stdenv.isDarwin) {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.operator6o-sapling-include.path;
    };
  };
}
