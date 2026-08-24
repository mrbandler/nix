{ inputs, ... }:
{
  flake-file.inputs.paneru = {
    url = "github:karinushka/paneru";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.desktop.provides.paneru.homeManager =
    { config, lib, ... }:
    let
      kb = config.desktop.keybindings;

      # "Mod2+H" -> "ctrl + alt - h" ; "Mod+3" -> "alt - 3"
      mods = {
        Mod = "fn";
        Mod2 = "fn + ctrl";
      };
      chord =
        bindStr:
        let
          parts = lib.splitString "+" bindStr;
          key = lib.toLower (lib.last parts);
          prefix = lib.concatMapStringsSep " + " (m: mods.${m}) (lib.init parts);
        in
        "${prefix} - ${key}";
      numBinds =
        action: prefix:
        lib.listToAttrs (
          map (n: {
            name = "${action}_${toString n}";
            value = chord "${prefix}+${toString n}";
          }) (lib.range 1 9)
        );
    in
    {
      imports = [
        inputs.paneru.homeModules.paneru
        ../core/_keybindings.nix
      ];

      services.paneru = {
        enable = true;

        settings = {
          options = {
            focus_follows_mouse = true;
            mouse_follows_focus = true;
            create_virtual_workspace_automatically = true;
            animation_speed = 14.0;
            virtual_workspace_animations = true;
          };

          decorations = {
            active.border = {
              enabled = true;
              color = config.lib.stylix.colors.withHashtag.base0E;
              width = 2.0;
              opacity = 1.0;
            };
            inactive.dim.opacity = 0.15;
          };

          padding = {
            top = 8;
            bottom = 8;
            left = 8;
            right = 8;
          };
          windows.all = {
            title = ".*";
            horizontal_padding = 8;
            vertical_padding = 8;
          };

          bindings = {
            window_focus_west = chord kb.navigation.focusColumnLeft;
            window_focus_east = chord kb.navigation.focusColumnRight;
            window_focus_north = chord kb.navigation.focusWindowUp;
            window_focus_south = chord kb.navigation.focusWindowDown;

            window_swap_west = chord kb.navigation.moveColumnLeft;
            window_swap_east = chord kb.navigation.moveColumnRight;
            window_swap_north = chord kb.navigation.moveWindowUp;
            window_swap_south = chord kb.navigation.moveWindowDown;

            window_resize = chord kb.layout.cyclePresetWidth;
            window_fullwidth = chord kb.layout.maximize;
            window_center = chord kb.layout.center;
            window_togglefloatlayer = chord kb.layout.toggleFloating;

            # niri's 4-directional monitor nav collapses to next-display
            window_nextdisplay = chord kb.monitor.focusMonitorLeft;
            window_nextdisplaysend = chord kb.monitor.moveToMonitorLeft;

            window_virtual_north = chord kb.navigation.focusWorkspaceUp;
            window_virtual_south = chord kb.navigation.focusWorkspaceDown;
            window_virtualmove_north = chord kb.navigation.moveToWorkspaceUp;
            window_virtualmove_south = chord kb.navigation.moveToWorkspaceDown;

            # Mod2+shift: escalation layer, clear of the move binds
            quit = "fn + ctrl + shift - q";
            restart = "fn + ctrl + shift - r";
          }
          // numBinds "window_virtualnum" kb.navigation.focusWorkspacePrefix
          // numBinds "window_virtualmovenum" kb.navigation.moveToWorkspacePrefix;
        };
      };
    };
}
