{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.identities.gouv;
  includePath = config.lib.file.mkOutOfStoreSymlink config.sops.templates.gouv-git-config.path;
  sshSigningKey = config.sops.placeholder.gouv-ssh-signing-key;

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
      enable = mkEnableOption "Jujutsu identity config for gouv" // {
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
      defaultSopsFile = ./../secrets/gouv.enc.yaml;
      secrets = {
        gouv-email = { };
        gouv-name = { };
        gouv-ssh-signing-key = { };
      };

      templates = {
        gouv-git-config = {
          file = gitIni.generate "config" (mkMerge [
            cfg.git.extraConfig
            {
              user = {
                email = config.sops.placeholder.gouv-email;
                name = config.sops.placeholder.gouv-name;
                signingkey = sshSigningKey;
              };
              commit.gpgsign = true;
              gpg.format = "ssh";
            }
          ]);
          mode = "0644";
        };

        gouv-jj-config = {
          file = toml.generate "config.toml" (mkMerge [
            cfg.jj.extraConfig
            {
              signing = {
                backend = "ssh";
                behavior = mkDefault "own";
                key = sshSigningKey;
              };
              user = {
                email = config.sops.placeholder.gouv-email;
                name = config.sops.placeholder.gouv-name;
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

    xdg.configFile."jj/conf.d/gouv.conf" = mkIf cfg.jj.enable {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.gouv-jj-config.path;
    };
  };
}
