{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.identities.shikanime;
  gitIni = pkgs.formats.gitIni { };
  toml = pkgs.formats.toml { };
in
{
  imports = [
    ./identities.nix
  ];

  options.identities.shikanime = {
    enable = mkEnableOption "the shikanime identity" // {
      default = false;
    };

    git = {
      enable = mkEnableOption "git identity includes for shikanime" // {
        default = config.programs.git.enable;
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
      enable = mkEnableOption "Jujutsu identity config for shikanime" // {
        default = config.programs.jujutsu.enable;
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

    sapling.enable = mkEnableOption "sapling identity config for shikanime" // {
      default = config.programs.sapling.enable;
    };
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ./../secrets/shikanime.enc.yaml;
      secrets = {
        shikanime-email = { };
        shikanime-gpg-key = { };
        shikanime-name = { };
        shikanime-ssh-signing-key = { };
      };

      templates = {
        shikanime-git-config = {
          file = gitIni.generate "config" (mkMerge [
            cfg.git.extraConfig
            {
              user = {
                email = config.sops.placeholder.shikanime-email;
                name = config.sops.placeholder.shikanime-name;
                signingkey = config.sops.placeholder.shikanime-ssh-signing-key;
              };
              commit.gpgsign = true;
              gpg.format = "ssh";
            }
          ]);
        };

        shikanime-jj-config = {
          file = toml.generate "config.toml" (mkMerge [
            cfg.jj.extraConfig
            {
              signing = {
                backend = "ssh";
                behavior = mkDefault "own";
                key = config.sops.placeholder.shikanime-ssh-signing-key;
              };
              user = {
                email = config.sops.placeholder.shikanime-email;
                name = config.sops.placeholder.shikanime-name;
              };
            }
          ]);
        };

        shikanime-sapling-include = {
          content = ''
            [commit]
            gpgsign = true

            [gpg]
            key = ${config.sops.placeholder.shikanime-gpg-key}

            [ui]
            username = ${config.sops.placeholder.shikanime-name} <${config.sops.placeholder.shikanime-email}>

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
          path = config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-git-config.path;
        }
        // optionalAttrs (cfg.git.condition != null) { condition = cfg.git.condition; }
      )
    ];

    xdg.configFile."jj/conf.d/shikanime.toml" = mkIf cfg.jj.enable {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-jj-config.path;
    };

    home.file."Library/Preferences/sapling/shikanime.conf" = mkIf pkgs.stdenv.isDarwin {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-sapling-include.path;
    };

    xdg.configFile."sapling/shikanime.conf" = mkIf (!pkgs.stdenv.isDarwin) {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-sapling-include.path;
    };
  };
}
