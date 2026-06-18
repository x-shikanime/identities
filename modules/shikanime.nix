{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.identities.shikanime;
  includePath = config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-git-config.path;
  sshSigningKey = config.sops.placeholder.shikanime-ssh-signing-key;

  gitIni = pkgs.formats.gitIni { };
  toml = pkgs.formats.toml { };
  fixedGitConfig = {
    user = {
      email = config.sops.placeholder.shikanime-email;
      name = config.sops.placeholder.shikanime-name;
      signingkey = sshSigningKey;
    };
    commit.gpgsign = true;
    gpg.format = "ssh";
  };
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
      enable = mkEnableOption "Jujutsu identity config for shikanime" // {
        default = true;
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

    sapling = {
      enable = mkEnableOption "sapling identity config for shikanime" // {
        default = true;
      };
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
            fixedGitConfig
          ]);
          mode = "0644";
        };

        shikanime-jj-config = {
          file = toml.generate "config.toml" (mkMerge [
            cfg.jj.extraConfig
            {
              signing = {
                backend = "ssh";
                behavior = mkDefault "own";
                key = sshSigningKey;
              };
              user = {
                email = config.sops.placeholder.shikanime-email;
                name = config.sops.placeholder.shikanime-name;
              };
            }
          ]);
          mode = "0644";
        };

        shikanime-sapling-config = {
          file = (pkgs.formats.ini { }).generate "sapling.conf" {
            ui.username = "${config.sops.placeholder.shikanime-name} <${config.sops.placeholder.shikanime-email}>";
            gpg.key = config.sops.placeholder.shikanime-gpg-key;
          };
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

    xdg.configFile."jj/conf.d/shikanime.toml" = mkIf cfg.jj.enable {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-jj-config.path;
    };

    home.file = mkIf pkgs.stdenv.isDarwin {
      "Library/Preferences/sapling/sapling.conf".source =
        config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-sapling-config.path;
    };

    xdg.configFile."sapling/sapling.conf" = mkIf (!pkgs.stdenv.isDarwin) {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.shikanime-sapling-config.path;
    };
  };
}
