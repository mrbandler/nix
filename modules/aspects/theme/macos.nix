# macOS-side cosmetics. The parts of the theme stylix cannot reach on darwin.
{
  den.aspects.theme = {
    provides.to-hosts.darwin.system.defaults = {
      NSGlobalDomain.AppleInterfaceStyle = "Dark";
      CustomUserPreferences.NSGlobalDomain = {
        AppleAccentColor = 5;
        AppleHighlightColor = "0.968627 0.831373 1.000000 Purple";
      };
    };

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && config.stylix.image != null) {
        home.activation.setWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          /usr/bin/osascript -e 'tell application "System Events" to tell every desktop to set picture to "${config.stylix.image}"' \
            || echo "setWallpaper: osascript failed — grant Automation (System Events) to the app running the switch" >&2
        '';
      };
  };
}
