{
  # macOS takes the vendor-signed cask: TCC grants (App Management, which
  # home-manager's copyApps needs) are pinned to the code signature, and the
  # ad-hoc signed nixpkgs build gets a new identity with every update. Only the
  # nightly cask is current; the stable one is stuck at the 20240203 release.
  den.aspects.cli.provides.to-hosts.darwin.homebrew.casks = [
    {
      name = "wezterm@nightly";
      # unversioned ("latest"), so brew only upgrades it greedily
      greedy = true;
    }
  ];

  den.aspects.cli.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # stands in for the package so the module's shell integration, and
      # getExe users like paneru, resolve to the cask app
      # casks land in ~/Applications (homebrew.caskArgs.appdir)
      caskApp = "${config.home.homeDirectory}/Applications/WezTerm.app/Contents";
      cask = pkgs.runCommandLocal "wezterm-cask" { meta.mainProgram = "wezterm"; } ''
        mkdir -p $out/bin $out/etc/profile.d
        ln -s ${caskApp}/MacOS/wezterm $out/bin/wezterm
        ln -s ${caskApp}/Resources/wezterm.sh $out/etc/profile.d/wezterm.sh
      '';
    in
    {
      programs.wezterm = {
        enable = true;
        package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin cask;

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
          -- absolute path: a wezterm launched from the GUI has no nix profile on PATH,
          -- and no XDG_CONFIG_HOME either, which nushell needs to find its config
          config.default_prog = { '${lib.getExe config.programs.nushell.package}' }
          config.set_environment_variables = { XDG_CONFIG_HOME = '${config.xdg.configHome}' }

          -- Disable Alt+Enter fullscreen toggle (managed by window manager)
          config.keys = {
            { key = 'Enter', mods = 'ALT', action = wezterm.action.DisableDefaultAssignment },
          }

          -- the scratch terminal is the window of the "scratch" workspace; the
          -- window manager finds it by this title prefix
          wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
            local title = tab.active_pane.title
            local window = wezterm.mux.get_window(tab.window_id)
            if window and window:get_workspace() == 'scratch' then
              return 'scratch: ' .. title
            end
            return title
          end)
        '';
      };
    };
}
