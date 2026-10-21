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
          ${ghostty} --args --title=scratch "--command=${lib.getExe pkgs.tuios} attach scratch -c"
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
