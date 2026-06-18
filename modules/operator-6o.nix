{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.identities.operator-6o;
  includePath = config.lib.file.mkOutOfStoreSymlink config.sops.templates.operator6o-git-config.path;
  sshSigningKey = config.sops.placeholder.operator6o-ssh-signing-key;

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
        default = true;
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
        default = false;
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
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ./../secrets/operator6o.enc.yaml;
      secrets = {
        operator6o-email = { };
        operator6o-name = { };
        operator6o-ssh-signing-key = { };
      };

      templates = {
        operator6o-git-config = {
          file = gitIni.generate "config" (mkMerge [
            cfg.git.extraConfig
            {
              user = {
                email = config.sops.placeholder.operator6o-email;
                name = config.sops.placeholder.operator6o-name;
                signingkey = sshSigningKey;
              };
              commit.gpgsign = true;
              gpg.format = "ssh";
            }
          ]);
          mode = "0644";
        };

        operator6o-jj-config = {
          file = toml.generate "config.toml" (mkMerge [
            cfg.jj.extraConfig
            {
              signing = {
                backend = "ssh";
                behavior = mkDefault "own";
                key = sshSigningKey;
              };
              user = {
                email = config.sops.placeholder.operator6o-email;
                name = config.sops.placeholder.operator6o-name;
              };
            }
          ]);
          mode = "0644";
        };
      };
    };

    programs.git.includes = mkIf cfg.git.enable [
      (
        {
          path = includePath;
        }
        // optionalAttrs (cfg.git.condition != null) { condition = cfg.git.condition; }
      )
    ];

    xdg.configFile."jj/conf.d/operator6o.conf" = mkIf cfg.jj.enable {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.operator6o-jj-config.path;
    };
  };
}
