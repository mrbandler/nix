# The creative bag: opt-in, included by the user. Vendor-signed apps go
# through casks on macOS; the rest comes from nixpkgs where it builds.
{
  den.aspects.creative = {
    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages =
          with pkgs;
          [
            # no usable cask for these; source builds, first launch registers them
            tenacity
            rapidraw
            # the cask was disabled upstream on 2026-09-01 (fails the Gatekeeper
            # check); zeus tracked darktable master for the AI modules, that
            # overlay returns with the host
            darktable
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            # no cask, and nixpkgs' darwin build breaks in postInstall on a
            # thumbnailer file only the Linux install has
            libresprite

            # 3D / CAD
            blender
            blockbench
            material-maker
            freecad

            # 2D
            krita
            graphite
            inkscape

            # Audio
            reaper

            # Game engines
            godot_4
            unityhub
          ];
      };

    # No cask: Blackmagic's download needs a custom strategy that homebrew-cask
    # rejects, so the free edition comes from the App Store (needs a signed-in
    # account, lands in /Applications like every App Store app).
    provides.to-hosts.darwin.homebrew.masApps."DaVinci Resolve" = 571213070;

    provides.to-hosts.darwin.homebrew.casks = [
      "blender"
      "blockbench"
      "material-maker"
      "freecad"
      "krita"
      "inkscape"
      "reaper"
      "godot"
      "unity-hub"
    ];
  };
}
