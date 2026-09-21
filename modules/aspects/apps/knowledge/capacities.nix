{
  den.aspects.apps = {
    homeManager =
      { lib, pkgs, ... }:
      {
        # nixpkgs only wraps the Linux AppImage; macOS gets the vendor-signed cask
        home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.capacities ];
      };

    provides.to-hosts.darwin.homebrew.casks = [ "capacities" ];
  };
}
