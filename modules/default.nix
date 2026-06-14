{ config, lib, ... }:

{
  imports = [
    ./base.nix
    ./identities.nix
    ./shikanime.nix
    ./gouv.nix
    ./operator-6o.nix
  ];

  options.identities = lib.mkOption {
    default = { };
    description = "Identity configuration.";
    type = lib.types.attrs;
  };
}
