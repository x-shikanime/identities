{ lib, ... }:

with lib;

{
  types.identity = types.submodule {
    options = {
      description = mkOption {
        description = "Human-readable description of this identity.";
        type = types.str;
      };

      email = mkOption {
        description = "Email address for this identity.";
        type = types.str;
      };

      gpgKey = mkOption {
        default = null;
        description = "GPG signing key ID.";
        type = types.nullOr types.str;
      };

      sshSigningKey = mkOption {
        default = null;
        description = "SSH signing key (public).";
        type = types.nullOr types.str;
      };

      name = mkOption {
        default = null;
        description = "Full name for this identity.";
        type = types.nullOr types.str;
      };
    };
  };
}
