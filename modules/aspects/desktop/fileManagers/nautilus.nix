{
  den.aspects.desktop.provides.nautilus.homeManager =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [ pkgs.nautilus ];

      dconf.settings = {
        "org/gnome/nautilus/preferences" = {
          default-folder-viewer = "list-view";
          show-hidden-files = true;
        };
        "org/gnome/nautilus/list-view" = {
          default-zoom-level = "small";
          use-tree-view = true;
        };
      };
    };
}
