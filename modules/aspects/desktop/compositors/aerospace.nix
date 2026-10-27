# AeroSpace on macOS: i3-style tiling on its own workspaces, driven by the
# shared keybinding map. Native fullscreen apps stay on their macOS Spaces.
{
  den.aspects.desktop.provides.aerospace.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      kb = config.desktop.keybindings;
      aerospace = lib.getExe config.programs.aerospace.package;

      # karabiner turns the Super chords into these, which no app uses
      # "Mod2+H" -> "ctrl-alt-shift-cmd-h"
      mods = {
        Mod = "ctrl-alt-shift";
        Mod2 = "ctrl-alt-shift-cmd";
      };
      keys = {
        return = "enter";
        bracketleft = "leftSquareBracket";
        bracketright = "rightSquareBracket";
      };
      chord =
        bindStr:
        let
          parts = lib.splitString "+" bindStr;
          key = lib.toLower (lib.last parts);
        in
        lib.concatStringsSep "-" (map (m: mods.${m}) (lib.init parts) ++ [ (keys.${key} or key) ]);
      numBinds =
        prefix: command:
        lib.listToAttrs (
          map (n: {
            name = chord "${prefix}+${toString n}";
            value = "${command} ${toString n}";
          }) (lib.range 1 9)
        );

      # AeroSpace runs commands without the nix profile on PATH: store paths only
      exec = command: "exec-and-forget ${command}";
      # the CLI cannot open windows on macOS; every window is its own instance
      ghostty = "open -na ${config.programs.ghostty.package}/Applications/Ghostty.app";
      zen = "${config.home.profileDirectory}/bin/zen-beta";

      # scratch terminal: a floating ghostty running the "scratch" tuios
      # session, stashed on workspace S while hidden. Its fixed "scratch" title
      # is how the window is found.
      # Ghostty titles the window only after it exists, too late for
      # on-window-detected, so the script floats it once the title shows up.
      # AeroSpace cannot size or place floating windows (upstream #9, #494), so
      # Ghostty opens at niri's 70% x 60%, centered: the focused screen's usable
      # area (AppKit, no permission needed) as a size in cells and a position,
      # which Ghostty takes relative to the visible area's top-left corner.
      # ponytail: cell size and window overhead measured on hermes (16pt
      # JetBrains Mono, -10% cell height); retune if the font changes.
      # NSScreen.mainScreen is a best guess at the focused display.
      scratchGeometry = pkgs.writeText "scratch-terminal-geometry.js" ''
        ObjC.import("AppKit");
        const cell = { width: 9.5, height: 19.1 };
        const overhead = { width: 40, height: 27 };
        const f = $.NSScreen.mainScreen.visibleFrame;
        const cols = Math.round((f.size.width * 0.7 - overhead.width) / cell.width);
        const rows = Math.round((f.size.height * 0.6 - overhead.height) / cell.height);
        const w = cols * cell.width + overhead.width;
        const h = rows * cell.height + overhead.height;
        [
          `--window-width=''${cols}`,
          `--window-height=''${rows}`,
          `--window-position-x=''${Math.round((f.size.width - w) / 2)}`,
          `--window-position-y=''${Math.round((f.size.height - h) / 2)}`,
        ].join(" ");
      '';
      scratchTerminal = pkgs.writeShellScript "toggle-scratch-terminal" ''
        find() {
          ${aerospace} list-windows --all --json \
            --format '%{window-id} %{app-bundle-id} %{window-title} %{workspace}' \
            | ${lib.getExe pkgs.jq} -r '.[] | select(."app-bundle-id" == "com.mitchellh.ghostty" and ."window-title" == "scratch") | "\(."window-id") \(.workspace)"' \
            | head -n1
        }
        id=$(find)
        if [ -z "$id" ]; then
          # one --command argument: Ghostty 1.3.1 takes a bare path argument
          # (`-e /nix/store/...`) for a file to open and asks before running it
          # shellcheck disable=SC2046
          ${ghostty} --args --title=scratch $(/usr/bin/osascript -l JavaScript ${scratchGeometry}) \
            "--command=${lib.getExe pkgs.tuios} attach scratch -c"
          for _ in $(seq 50); do
            id=$(find)
            [ -n "$id" ] && exec ${aerospace} layout --window-id "''${id%% *}" floating
            sleep 0.1
          done
          exit 1
        fi
        window=''${id%% *}
        current=$(${aerospace} list-workspaces --focused)
        if [ "''${id#* }" = "$current" ]; then
          ${aerospace} move-node-to-workspace --window-id "$window" S
        else
          ${aerospace} move-node-to-workspace --window-id "$window" "$current"
          ${aerospace} focus --window-id "$window"
        fi
      '';
    in
    {
      imports = [ ../core/_keybindings.nix ];

      config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        programs.aerospace = {
          enable = true;
          launchd.enable = true;

          settings = {
            config-version = 2;
            # version 2 no longer infers these from the bindings
            persistent-workspaces = map toString (lib.range 1 9);

            gaps = {
              inner.horizontal = 8;
              inner.vertical = 8;
              outer = {
                left = 8;
                right = 8;
                top = 8;
                bottom = 8;
              };
            };

            on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

            on-window-detected = [
              {
                # the script floats it too, should Ghostty title it late
                "if" = {
                  app-id = "com.mitchellh.ghostty";
                  window-title-regex-substring = "^scratch$";
                };
                run = [ "layout floating" ];
              }
              {
                # 1Password's unlock and authorization prompts are not dialogs
                # to macOS; tiled they squash the layout
                "if".app-id = "com.1password.1password";
                run = [ "layout floating" ];
              }
            ];

            mode.main.binding = {
              ${chord kb.launcher} = exec "${config.home.profileDirectory}/bin/vicinae toggle";
              ${chord kb.applications.terminal} = exec ghostty;
              ${chord kb.applications.scratchTerminal} = exec "${scratchTerminal}";
              ${chord kb.applications.fileManager} = exec "open ~";
              ${chord kb.applications.browser} = exec zen;
              ${chord kb.applications.privateBrowser} = exec "${zen} --private-window";

              ${chord kb.navigation.focusColumnLeft} = "focus left";
              ${chord kb.navigation.focusColumnRight} = "focus right";
              ${chord kb.navigation.focusWindowUp} = "focus up";
              ${chord kb.navigation.focusWindowDown} = "focus down";
              ${chord kb.navigation.moveColumnLeft} = "move left";
              ${chord kb.navigation.moveColumnRight} = "move right";
              ${chord kb.navigation.moveWindowUp} = "move up";
              ${chord kb.navigation.moveWindowDown} = "move down";
              ${chord kb.navigation.consumeFromLeft} = "join-with left";
              ${chord kb.navigation.consumeFromRight} = "join-with right";

              ${chord kb.navigation.focusWorkspaceUp} = "workspace prev";
              ${chord kb.navigation.focusWorkspaceDown} = "workspace next";
              ${chord kb.navigation.moveToWorkspaceUp} = "move-node-to-workspace prev";
              ${chord kb.navigation.moveToWorkspaceDown} = "move-node-to-workspace next";

              ${chord kb.monitor.focusMonitorLeft} = "focus-monitor left";
              ${chord kb.monitor.focusMonitorRight} = "focus-monitor right";
              ${chord kb.monitor.focusMonitorUp} = "focus-monitor up";
              ${chord kb.monitor.focusMonitorDown} = "focus-monitor down";
              ${chord kb.monitor.moveToMonitorLeft} = "move-node-to-monitor left";
              ${chord kb.monitor.moveToMonitorRight} = "move-node-to-monitor right";
              ${chord kb.monitor.moveToMonitorUp} = "move-node-to-monitor up";
              ${chord kb.monitor.moveToMonitorDown} = "move-node-to-monitor down";

              ${chord kb.layout.resizeWidthDecrease} = "resize width -50";
              ${chord kb.layout.resizeWidthIncrease} = "resize width +50";
              ${chord kb.layout.resizeHeightDecrease} = "resize height -50";
              ${chord kb.layout.resizeHeightIncrease} = "resize height +50";
              ${chord kb.layout.maximize} = "fullscreen";
              ${chord kb.layout.fullscreen} = "macos-native-fullscreen";
              ${chord kb.layout.toggleFloating} = "layout floating tiling";
              ${chord kb.layout.toggleTabbed} = "layout tiles accordion";
            }
            // lib.genAttrs (map chord kb.window.close) (_: "close")
            // numBinds kb.navigation.focusWorkspacePrefix "workspace"
            // numBinds kb.navigation.moveToWorkspacePrefix "move-node-to-workspace";
          };
        };

        # the module reloads only from the config file's onChange, which has not
        # always taken effect; reload on every activation, once the new config
        # is linked and the agent is up
        home.activation.aerospaceReload =
          lib.hm.dag.entryAfter
            [
              "onFilesChange"
              "setupLaunchAgents"
            ]
            ''
              if ${aerospace} list-modes --current >/dev/null 2>&1; then
                run ${aerospace} reload-config
              fi
            '';

        # the focus outline paneru used to draw
        services.jankyborders = {
          enable = true;
          settings = {
            style = "round";
            width = 2.0;
            active_color = "0xff${config.lib.stylix.colors.base0E}";
            inactive_color = "0x00000000";
          };
        };
      };
    };
}
