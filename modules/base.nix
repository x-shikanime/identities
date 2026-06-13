# Shared identity types.
{ lib, ... }:

with lib;

{
  types.identity = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Full name for this identity.";
      };

      email = mkOption {
        type = types.str;
        description = "Email address for this identity.";
      };

      gpgKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "GPG signing key ID.";
      };
    };
  };
}
