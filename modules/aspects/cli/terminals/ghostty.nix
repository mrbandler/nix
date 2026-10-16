# Linux only for now; macOS stays on wezterm until paneru's scratch terminal
# moves over. Colors and fonts come from the stylix target; this is the rest,
# carried over from the wezterm config.
{
  den.aspects.cli.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.ghostty = {
        enable = true;

        settings = {
          command = lib.getExe config.programs.nushell.package;

          # borderless, no chrome: the window manager does the framing
          window-decoration = "none";
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
        };
      };
    };
}
