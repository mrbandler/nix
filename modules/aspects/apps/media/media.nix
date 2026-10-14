# GNOME's scanner, PDF and image tools have no place on macOS (Image Capture
# and Preview cover them), so they stay with Linux.
{
  den.aspects.apps.homeManager =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = with pkgs; [
        simple-scan
        pdfarranger
        loupe
      ];

      xdg.mimeApps.defaultApplications = lib.genAttrs [
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/svg+xml"
        "image/bmp"
        "image/tiff"
        "image/avif"
        "image/jxl"
      ] (_: "org.gnome.Loupe.desktop");
    };
}
