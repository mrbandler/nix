{
  den.aspects.apps = {
    homeManager =
      { lib, pkgs, ... }:
      {
        programs.obsidian.enable = lib.mkDefault pkgs.stdenv.isLinux;
      };

    provides.to-hosts.darwin.homebrew.casks = [ "obsidian" ];
  };
}
