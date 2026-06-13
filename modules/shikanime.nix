# Shikanime identity — primary persona for Shikanime Studio work.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.identities.shikanime;

  gitConfig = pkgs.writeText "git-config-shikanime" ''
    [user]
      name = ${cfg.name}
      email = ${cfg.email}
    [commit]
      gpgsign = true
    [user]
      signingkey = ${cfg.sshSigningKey or cfg.gpgKey or ""}
  '';

  jjConfig = pkgs.writeText "jj-config-shikanime.toml" ''
    [user]
    name = "${cfg.name}"
    email = "${cfg.email}"

    [signing]
    backend = "${cfg.signingBackend}"
    behavior = "own"
    key = "${cfg.sshSigningKey or cfg.gpgKey or ""}
  '';
in
{
  options.identities.shikanime = {
    enable = mkEnableOption "the shikanime identity";

    name = mkOption {
      type = types.str;
      default = "Shikanime Deva";
      description = "Git commit author name.";
    };

    email = mkOption {
      type = types.str;
      default = "william.phetsinorath@shikanime.studio";
      description = "Git commit author email.";
    };

    gpgKey = mkOption {
      type = types.nullOr types.str;
      default = "09CA52A835C14157";
      description = "GPG signing key ID.";
    };

    signingBackend = mkOption {
      type = types.enum [ "gpg" "ssh" ];
      default = "ssh";
      description = "Commit signing backend.";
    };

    sshSigningKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "SSH public key for commit signing.";
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."git/config.d/shikanime".source = gitConfig;
    xdg.configFile."jj/conf.d/shikanime.toml".source = jjConfig;
  };
}
