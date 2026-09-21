{ inputs, ... }:
{
  flake-file.inputs.paneru = {
    url = "github:karinushka/paneru";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Configured through paneru's Lua mode: the TOML table becomes paneru.setup,
  # and the application launches and the scratch terminal need bind callbacks
  # the TOML cannot express.
  den.aspects.desktop.provides.paneru.homeManager =
    {
      config,
      lib,
      ...
    }:
    let
      kb = config.desktop.keybindings;

      # "Mod2+H" -> "fn + ctrl - h" ; "Mod+3" -> "fn - 3"
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
        command: prefix:
        lib.listToAttrs (
          map (n: {
            name = "${command} ${toString n}";
            value = chord "${prefix}+${toString n}";
          }) (lib.range 1 9)
        );

      # paneru's launchd environment has no nix profile on PATH: store paths only
      wezterm = lib.getExe config.programs.wezterm.package;
      zellij = lib.getExe config.programs.zellij.package;
      zen = "${config.home.profileDirectory}/bin/zen-beta";

      # what paneru runs when a launch key is pressed
      launches = {
        ${kb.applications.terminal} = "${wezterm} start";
        ${kb.applications.fileManager} = "open ~";
        ${kb.applications.browser} = zen;
        ${kb.applications.privateBrowser} = "${zen} --private-window";
      };

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
        windows = {
          all = {
            title = ".*";
            horizontal_padding = 8;
            vertical_padding = 8;
          };
          # the window server reports a 0 radius for wezterm's window
          # although it draws the standard 12; the border would come out square
          wezterm = {
            title = ".*";
            bundle_id = "com.github.wez.wezterm";
            border_radius = 12.0;
          };
        };

        bindings = {
          "window focus west" = chord kb.navigation.focusColumnLeft;
          "window focus east" = chord kb.navigation.focusColumnRight;
          "window focus north" = chord kb.navigation.focusWindowUp;
          "window focus south" = chord kb.navigation.focusWindowDown;

          "window swap west" = chord kb.navigation.moveColumnLeft;
          "window swap east" = chord kb.navigation.moveColumnRight;
          "window swap north" = chord kb.navigation.moveWindowUp;
          "window swap south" = chord kb.navigation.moveWindowDown;

          "window resize" = chord kb.layout.cyclePresetWidth;
          "window fullwidth" = chord kb.layout.maximize;
          "window center" = chord kb.layout.center;
          "window togglefloatlayer" = chord kb.layout.toggleFloating;

          # niri's 4-directional monitor nav collapses to next-display
          "window nextdisplay" = chord kb.monitor.focusMonitorLeft;
          "window nextdisplaysend" = chord kb.monitor.moveToMonitorLeft;

          "window virtual north" = chord kb.navigation.focusWorkspaceUp;
          "window virtual south" = chord kb.navigation.focusWorkspaceDown;
          "window virtualmove north" = chord kb.navigation.moveToWorkspaceUp;
          "window virtualmove south" = chord kb.navigation.moveToWorkspaceDown;

          # Mod2+shift: escalation layer, clear of the move binds
          quit = "fn + ctrl + shift - q";
          restart = "fn + ctrl + shift - r";
        }
        // numBinds "window virtualnum" kb.navigation.focusWorkspacePrefix
        // numBinds "window virtualmovenum" kb.navigation.moveToWorkspacePrefix;
      };

      initLua = ''
        paneru.setup(${lib.generators.toLua { } settings})

        -- application launches
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (bind: command: ''
            paneru.bind(${builtins.toJSON (chord bind)}, function()
              os.execute(${builtins.toJSON "${command} &"})
            end)
          '') launches
        )}

        -- scratch terminal: a floating wezterm running the "scratch" zellij
        -- session, parked on a workspace nobody looks at while hidden. wezterm
        -- prefixes the title of its "scratch" workspace so the window is found.
        local scratch = {
          stash = 9,
          match = paneru.match { bundle = "com.github.wez.wezterm", title = "^scratch" },
          spawn = ${builtins.toJSON "${wezterm} start --workspace scratch -- ${zellij} attach --create scratch &"},
        }

        -- float it once it is recognisable: wezterm sets the title only after the
        -- window exists, so the spawn event may still carry the initial title
        local function place(ws, id)
          local window = ws:find(scratch.match)
          if window and window.id == id and not window.floating then
            return ws:float(id, { x = 0.15, y = 0.1, width = 0.7, height = 0.6 })
          end
        end

        paneru.on("window_spawned", function(event, ws)
          return place(ws, event.window_id)
        end)

        paneru.on("window_title_changed", function(event, ws)
          return place(ws, event.window_id)
        end)

        paneru.bind(${builtins.toJSON (chord kb.applications.scratchTerminal)}, function(ws)
          local window = ws:find(scratch.match)
          if not window then
            os.execute(scratch.spawn)
            return
          end
          if ws:workspace_of(window.id) == ws:current() then
            return ws:shift(window.id, scratch.stash)
          end
          return ws:shift(window.id, ws:current(), true):focus(window.id)
        end)
      '';
    in
    {
      imports = [
        inputs.paneru.homeModules.paneru
        ../core/_keybindings.nix
      ];

      services.paneru = {
        enable = true;
        config = initLua;
      };
    };
}
