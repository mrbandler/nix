# Colors and fonts come from the stylix target; this is the rest, carried over
# from the wezterm config.
{
  den.aspects.cli.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
    in
    {
      programs.ghostty = {
        enable = true;
        # macOS takes the upstream app with its Developer ID signature intact:
        # TCC grants (App Management, which `nx rebuild` needs) are pinned to
        # the signature, so they survive updates
        package = lib.mkIf isDarwin pkgs.ghostty-bin;

        settings = {
          command = lib.getExe config.programs.nushell.package;

          window-padding-x = 6;
          window-padding-y = 6;
          window-padding-balance = true;
          scrollbar = "never";
          resize-overlay = "never";
          confirm-close-surface = false;

          adjust-cell-height = "-10%";
          cursor-style = "underline";
          cursor-style-blink = true;
          # the shell integration would turn the cursor into a bar at the prompt
          shell-integration-features = "no-cursor";

          # fullscreen belongs to the window manager
          keybind = [ "ctrl+enter=unbind" ];
        }
        // (
          if isDarwin then
            {
              # borderless, but with the native frame so paneru can resize it
              macos-titlebar-style = "hidden";
              # a Ghostty launched from the GUI has no XDG_CONFIG_HOME, which
              # nushell needs to find its config
              env = [ "XDG_CONFIG_HOME=${config.xdg.configHome}" ];
              # the app lives in the read-only store; updates come through nix
              auto-update = "off";
              # every window is its own `open -n` instance (the CLI can't open
              # windows on macOS); don't leave them running empty
              quit-after-last-window-closed = true;
            }
          else
            {
              # borderless, no chrome: the window manager does the framing
              window-decoration = "none";
            }
        );
      };
    };
}
