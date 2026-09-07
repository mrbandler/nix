{
  den.aspects.creative = {
    homeManager =
      { pkgs, ... }:
      {
        # the wlroots capture plugin is a Wayland concept and returns with zeus
        programs.obs-studio.enable = pkgs.stdenv.hostPlatform.isLinux;
      };

    provides.to-hosts.darwin.homebrew.casks = [ "obs" ];
  };
}
