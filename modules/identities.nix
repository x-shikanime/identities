{ config, lib, ... }:

with lib;

{
  options.identities = {
    enable = mkEnableOption "all identity modules";

    git.enable = mkEnableOption "git identity includes for all enabled identities" // {
      default = config.programs.git.enable;
    };

    jj.enable = mkEnableOption "Jujutsu identity configs for all enabled identities" // {
      default = config.programs.jujutsu.enable;
    };

    sapling.enable = mkEnableOption "sapling identity config for all enabled identities" // {
      default = config.programs.sapling.enable;
    };

    ghstack.enable = mkEnableOption "ghstack config for all enabled identities" // {
      default = false;
    };

    glab.enable = mkEnableOption "glab config for all enabled identities" // {
      default = false;
    };
  };
}
