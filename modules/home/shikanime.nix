{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.identities.shikanime;
  ini = pkgs.formats.ini { };
  gitIni = pkgs.formats.gitIni { };
  yaml = pkgs.formats.yaml { };
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
        default = config.identities.git.extraConfig;
        description = ''
          Extra git config merged into the generated identity include.
          Signing settings are fixed by this module and cannot be overridden.
        '';
        type = types.attrs;
      };
    };

    jj = {
      enable = mkEnableOption "Jujutsu identity config for shikanime" // {
        default = config.identities.jj.enable;
      };

      extraConfig = mkOption {
        default = config.identities.jj.extraConfig;
        description = ''
          Extra Jujutsu config merged into the generated identity include.
          Signing settings are fixed by this module and cannot be overridden.
        '';
        type = types.attrs;
      };
    };

    ghstack = {
      enable = mkEnableOption "ghstack config for shikanime" // {
        default = config.identities.ghstack.enable;
      };

      extraConfig = mkOption {
        default = config.identities.ghstack.extraConfig;
        description = ''
          Extra ghstack config merged into the generated config.
          The GitHub identity fields are fixed by the module and cannot be
          overridden.
        '';
        type = types.attrs;
      };
    };

    glab = {
      enable = mkEnableOption "glab config for shikanime" // {
        default = config.identities.glab.enable;
      };

      extraConfig = mkOption {
        default = config.identities.glab.extraConfig;
        description = ''
          Extra glab config merged into the generated config.
          The GitLab host and token fields are fixed by the module and cannot be
          overridden.
        '';
        type = types.attrs;
      };
    };
  };

  config = mkIf cfg.enable {
    sops = {
      secrets = {
        shikanime-email.sopsFile = ./../secrets/shikanime.enc.yaml;
        github-token.sopsFile = ./../secrets/shikanime.enc.yaml;
        gitlab-token.sopsFile = ./../secrets/shikanime.enc.yaml;
        shikanime-gpg-key.sopsFile = ./../secrets/shikanime.enc.yaml;
        shikanime-name.sopsFile = ./../secrets/shikanime.enc.yaml;
        shikanime-ssh-signing-key.sopsFile = ./../secrets/shikanime.enc.yaml;
      };

      templates = {
        shikanime-git-config = {
          file = gitIni.generate "config" (
            recursiveUpdate cfg.git.extraConfig {
              user = {
                email = config.sops.placeholder.shikanime-email;
                name = config.sops.placeholder.shikanime-name;
                signingkey = config.sops.placeholder.shikanime-ssh-signing-key;
              };
              commit.gpgsign = true;
              gpg.format = "ssh";
            }
          );
        };

        shikanime-jj-config = {
          file = toml.generate "config.toml" (
            recursiveUpdate cfg.jj.extraConfig {
              signing = {
                backend = "ssh";
                behavior = "own";
                key = config.sops.placeholder.shikanime-ssh-signing-key;
              };
              user = {
                email = config.sops.placeholder.shikanime-email;
                name = config.sops.placeholder.shikanime-name;
              };
            }
          );
        };

        ghstack-config = mkIf cfg.ghstack.enable {
          file = ini.generate "ghstackrc" (
            recursiveUpdate cfg.ghstack.extraConfig {
              ghstack = {
                github_oauth = config.sops.placeholder.github-token;
                github_url = "github.com";
                github_username = "shikanime";
              };
            }
          );
          mode = "0640";
        };

        glab-cli-config = mkIf cfg.glab.enable {
          file = yaml.generate "config.yaml" (
            recursiveUpdate cfg.glab.extraConfig {
              git_protocol = "https";
              hosts.gitlab.com = {
                api_host = "gitlab.com";
                api_protocol = "https";
                token = config.sops.placeholder.gitlab-token;
              };
            }
          );
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

    home.sessionVariables = mkIf cfg.ghstack.enable {
      GHSTACKRC_PATH = config.lib.file.mkOutOfStoreSymlink config.sops.templates.ghstack-config.path;
    };

    xdg.configFile."glab-cli/shikanime/config.yml" = mkIf cfg.glab.enable {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates.glab-cli-config.path;
    };
  };
}
