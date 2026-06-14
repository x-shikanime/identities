# Shared identity types.
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
    };
  };
}
