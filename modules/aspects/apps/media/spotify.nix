{
  den.aspects.apps = {
    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.spotify ];
      };

    provides.to-hosts.darwin.homebrew.casks = [ "spotify" ];
  };
}
