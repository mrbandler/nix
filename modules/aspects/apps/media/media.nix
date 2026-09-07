# GNOME's scanner and PDF tools have no place on macOS (Image Capture and
# Preview cover both), so they stay with Linux.
{
  den.aspects.apps.homeManager =
    { lib, pkgs, ... }:
    {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
        with pkgs;
        [
          simple-scan
          pdfarranger
        ]
      );
    };
}
