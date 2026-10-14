{ den, ... }:
{
  den.aspects.storage = {
    # nixpkgs flags ventoy's bundled binary blobs; the version bump on a lock
    # update makes this fail loudly, which is the point
    includes = [ (den.batteries.insecure [ "ventoy-1.1.17" ]) ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
          with pkgs;
          [
            cryptomator
            veracrypt
            ventoy
            ledger-live-desktop
            file-roller
            gnome-disk-utility
          ]
        );
      };

    provides.to-hosts.darwin.homebrew.casks = [
      {
        name = "google-drive";
        args.appdir = "/Applications";
      }
      {
        name = "proton-drive";
        args.appdir = "/Applications";
      }
    ];
  };
}
