{
  den.aspects.cli.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.wezterm = {
        enable = true;

        # Colors and fonts come from the stylix target; this is the rest.
        extraConfig = ''
          config.window_close_confirmation = 'NeverPrompt'
          config.line_height = 0.9
          config.enable_scroll_bar = false
          config.enable_tab_bar = false
          config.hide_tab_bar_if_only_one_tab = true
          -- borderless; macOS keeps the resize edges so the window manager can size it
          config.window_decorations = '${if pkgs.stdenv.hostPlatform.isDarwin then "RESIZE" else "NONE"}'
          config.window_padding = {
            left = '0.5cell',
            right = '0.5cell',
            top = '0.5cell',
            bottom = '0.5cell',
          }
          config.default_cursor_style = 'BlinkingUnderline'
          config.font = wezterm.font_with_fallback({
            'JetBrainsMono Nerd Font',
            'Symbols Nerd Font Mono',
            'Symbola',
          })
          config.adjust_window_size_when_changing_font_size = true
          -- absolute path: a wezterm launched from the GUI has no nix profile on PATH
          config.default_prog = { '${lib.getExe config.programs.nushell.package}' }

          -- Disable Alt+Enter fullscreen toggle (managed by window manager)
          config.keys = {
            { key = 'Enter', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment },
          }
        '';
      };
    };
}
