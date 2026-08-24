{
  den.aspects.mrbandler.provides.to-hosts.darwin.system.defaults = {
    dock = {
      autohide = true;
      tilesize = 47;
      show-recents = false;
      static-only = true;
      # captured: bottom-right hot corner = Quick Note
      wvous-br-corner = 14;
    };

    finder = {
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = true;
      ShowRemovableMediaOnDesktop = true;

      NewWindowTarget = "Home";

      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv"; # list view
      _FXSortFoldersFirst = true;
      AppleShowAllFiles = true; # hidden files
      FXEnableExtensionChangeWarning = false;
      FXDefaultSearchScope = "SCcf"; # search the current folder, not This Mac
    };

    NSGlobalDomain = {
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
      # captured: small sidebar icon size (Appearance)
      NSTableViewDefaultSizeMode = 1;
      # developer set: always show file extensions
      AppleShowAllExtensions = true;
    };

    WindowManager = {
      GloballyEnabled = false;
      EnableTilingByEdgeDrag = false;
      EnableTopTilingByEdgeDrag = false;
      EnableTilingOptionAccelerator = false;
      EnableTiledWindowMargins = false;
      HideDesktop = true;
      StandardHideDesktopIcons = true;
      StandardHideWidgets = true;
      StageManagerHideWidgets = true;
      AppWindowGroupingBehavior = true;
      AutoHide = true;
    };

    loginwindow.LoginwindowText = "It's about consistency and being consistent.";

    CustomUserPreferences = {
      "com.apple.spaces"."spans-displays" = false;
      "com.apple.finder" = {
        SidebarShowingiCloudDesktop = false;
        ShowRecentTags = false;
      };

      "com.apple.HIToolbox" = {
        AppleEnabledInputSources = [
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = 0;
            "KeyboardLayout Name" = "U.S.";
          }
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = 3;
            "KeyboardLayout Name" = "German";
          }
        ];
        # fn-tap is the vicinae launcher now (karabiner); 0 = fn does nothing
        # system-side. Layout switching lives on ctrl-space instead (below).
        AppleFnUsageType = 0;
      };
    };
  };

  den.aspects.mrbandler.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf pkgs.stdenv.isDarwin {

      # Layout switching on ctrl-space (fn-tap became the launcher; the
      # launcher chord moved to fn+space, freeing ctrl-space back up).
      home.activation.inputSourceHotkeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 \
          "{enabled = 1; value = { parameters = (32, 49, 262144); type = standard; };}"
        /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 \
          "{enabled = 1; value = { parameters = (32, 49, 786432); type = standard; };}"
      '';

      home.activation.finderSidebar = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        _mysides=${pkgs.mysides}/bin/mysides
        _desired="Applications -> file:///Applications/
        Desktop -> file://${config.home.homeDirectory}/Desktop/
        Downloads -> file://${config.home.homeDirectory}/Downloads/
        Pictures -> file://${config.home.homeDirectory}/Pictures/"
        _desired="$(echo "$_desired" | sed 's/^[[:space:]]*//')"
        _current="$("$_mysides" list 2>/dev/null)"
        if [ "$_current" != "$_desired" ]; then
          echo "finderSidebar: converging sidebar favorites"
          while IFS= read -r _line; do
            [ -n "$_line" ] && "$_mysides" remove "''${_line%% -> *}" >/dev/null 2>&1 || true
          done <<< "$_current"
          "$_mysides" add Applications file:///Applications/ >/dev/null
          "$_mysides" add Desktop "file://${config.home.homeDirectory}/Desktop/" >/dev/null
          "$_mysides" add Downloads "file://${config.home.homeDirectory}/Downloads/" >/dev/null
          "$_mysides" add Pictures "file://${config.home.homeDirectory}/Pictures/" >/dev/null
        fi
      '';
    };
}
