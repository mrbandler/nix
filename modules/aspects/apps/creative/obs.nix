{
  den.aspects.creative = {
    homeManager =
      { pkgs, ... }:
      {
        programs.obs-studio = {
          enable = pkgs.stdenv.hostPlatform.isLinux;
          # screen capture on wlroots-style Wayland compositors
          plugins = [ pkgs.obs-studio-plugins.wlrobs ];
        };
      };

    provides.to-hosts.darwin.homebrew.casks = [ "obs" ];
  };
}
