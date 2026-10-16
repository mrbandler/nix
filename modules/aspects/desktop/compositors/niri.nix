# niri from nixpkgs; its config.kdl is generated here from the shared
# keybinding contract (Mod = Super, Mod2 = Super+Alt) and checked with
# `niri validate` at build time. Hosts add outputs, workspaces, window rules
# and startup programs through desktop.niri.extraConfig.
{
  den.aspects.desktop.provides.niri = {
    provides.to-hosts.nixos =
      { pkgs, ... }:
      {
        programs.niri.enable = true;
        # niri spawns it on demand for X11 clients
        environment.systemPackages = [ pkgs.xwayland-satellite ];
      };

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        kb = config.desktop.keybindings;
        colors = config.lib.stylix.colors.withHashtag;

        # "Mod2+H" -> "Super+Alt+H"
        mods = {
          Mod = "Super";
          Mod2 = "Super+Alt";
        };
        key = bindStr: lib.concatMapStringsSep "+" (p: mods.${p} or p) (lib.splitString "+" bindStr);

        # bind "Mod+H" "focus-column-left" -> "Super+H" { focus-column-left; }
        bindWith =
          props: bindStr: action:
          ''"${key bindStr}" ${props}{ ${action}; }'';
        bind = bindWith "";
        spawn = args: "spawn ${lib.concatMapStringsSep " " builtins.toJSON args}";
        noctalia =
          args:
          spawn (
            [
              "noctalia"
              "msg"
            ]
            ++ args
          );

        ghostty = lib.getExe config.programs.ghostty.package;
        tuios = lib.getExe pkgs.tuios;
        zen = "${config.home.profileDirectory}/bin/zen-beta";

        # the scratch terminal is closed and respawned; its tuios session
        # keeps the state in between
        scratchTerminal = pkgs.writeShellScript "toggle-scratch-terminal" ''
          id=$(niri msg --json windows | ${lib.getExe pkgs.jq} -r '.[] | select(.app_id == "dev.mrbandler.scratch-terminal") | .id' | head -n1)
          if [ -n "$id" ]; then
            niri msg action close-window --id "$id"
          else
            ${ghostty} --class=dev.mrbandler.scratch-terminal -e ${tuios} attach scratch -c
          fi
        '';

        nav = kb.navigation;
        lay = kb.layout;
        mon = kb.monitor;
        app = kb.applications;

        binds = [
          # tapping Super alone sends F13 (keyd), which XKB names XF86Tools
          "XF86Tools { ${
            spawn [
              "vicinae"
              "toggle"
            ]
          }; }"

          (bind app.terminal (spawn [ ghostty ]))
          (bind app.scratchTerminal (spawn [ "${scratchTerminal}" ]))
          (bind app.fileManager (spawn [ "nautilus" ]))
          (bind app.browser (spawn [ zen ]))
          (bind app.privateBrowser (spawn [
            zen
            "--private-window"
          ]))
          (bind app.passwordManager (spawn [
            "1password"
            "--quick-access"
          ]))

          (bindWith "repeat=false " kb.window.overview "toggle-overview")
          (bindWith "allow-inhibiting=false " kb.window.inhibitShortcuts "toggle-keyboard-shortcuts-inhibit")

          (bind nav.focusColumnLeft "focus-column-left")
          (bind nav.focusColumnRight "focus-column-right")
          (bind nav.focusWindowUp "focus-window-up")
          (bind nav.focusWindowDown "focus-window-down")
          (bind nav.moveColumnLeft "move-column-left")
          (bind nav.moveColumnRight "move-column-right")
          (bind nav.moveWindowUp "move-window-up")
          (bind nav.moveWindowDown "move-window-down")
          (bind nav.focusWorkspaceUp "focus-workspace-up")
          (bind nav.focusWorkspaceDown "focus-workspace-down")
          (bind nav.moveToWorkspaceUp "move-column-to-workspace-up")
          (bind nav.moveToWorkspaceDown "move-column-to-workspace-down")
          (bind nav.focusFirstColumn "focus-column-first")
          (bind nav.focusLastColumn "focus-column-last")
          (bind nav.moveColumnFirst "move-column-to-first")
          (bind nav.moveColumnLast "move-column-to-last")
          (bind nav.consumeFromLeft "consume-or-expel-window-left")
          (bind nav.consumeFromRight "consume-or-expel-window-right")
          (bind nav.expelToLeft "consume-or-expel-window-left")
          (bind nav.expelToRight "consume-or-expel-window-right")

          "Super+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }"
          "Super+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }"

          (bind mon.focusMonitorLeft "focus-monitor-left")
          (bind mon.focusMonitorRight "focus-monitor-right")
          (bind mon.focusMonitorDown "focus-monitor-down")
          (bind mon.focusMonitorUp "focus-monitor-up")
          (bind mon.moveToMonitorLeft "move-column-to-monitor-left")
          (bind mon.moveToMonitorRight "move-column-to-monitor-right")
          (bind mon.moveToMonitorDown "move-column-to-monitor-down")
          (bind mon.moveToMonitorUp "move-column-to-monitor-up")

          (bind lay.resizeWidthDecrease ''set-column-width "-10%"'')
          (bind lay.resizeWidthIncrease ''set-column-width "+10%"'')
          (bind lay.resizeHeightDecrease ''set-window-height "-10%"'')
          (bind lay.resizeHeightIncrease ''set-window-height "+10%"'')
          (bind lay.cyclePresetWidth "switch-preset-column-width")
          (bind lay.cyclePresetHeight "switch-preset-window-height")
          (bind lay.maximize "maximize-column")
          (bind lay.fullscreen "fullscreen-window")
          (bind lay.expand "expand-column-to-available-width")
          (bind lay.center "center-column")
          (bind lay.toggleFloating "toggle-window-floating")
          (bind lay.switchFloatingFocus "switch-focus-between-floating-and-tiling")
          (bind lay.toggleTabbed "toggle-column-tabbed-display")

          (bind kb.shell.notifications (noctalia [
            "panel-toggle"
            "control-center"
          ]))
          (bind kb.shell.lock (noctalia [
            "session"
            "lock"
          ]))
          (bind kb.shell.session (noctalia [
            "panel-toggle"
            "session"
          ]))

          "Print { screenshot; }"
          "Ctrl+Print { screenshot-screen; }"
          "Alt+Print { screenshot-window; }"

          "XF86AudioRaiseVolume allow-when-locked=true { ${noctalia [ "volume-up" ]}; }"
          "XF86AudioLowerVolume allow-when-locked=true { ${noctalia [ "volume-down" ]}; }"
          "XF86AudioMute allow-when-locked=true { ${noctalia [ "volume-mute" ]}; }"
          "XF86AudioMicMute allow-when-locked=true { ${noctalia [ "mic-mute" ]}; }"
          "XF86AudioPlay allow-when-locked=true { ${
            noctalia [
              "media"
              "toggle"
            ]
          }; }"
          "XF86AudioStop allow-when-locked=true { ${
            noctalia [
              "media"
              "stop"
            ]
          }; }"
          "XF86AudioPrev allow-when-locked=true { ${
            noctalia [
              "media"
              "previous"
            ]
          }; }"
          "XF86AudioNext allow-when-locked=true { ${
            noctalia [
              "media"
              "next"
            ]
          }; }"
        ]
        ++ map (bindStr: bindWith "repeat=false " bindStr "close-window") kb.window.close
        ++ lib.concatMap (n: [
          (bind "${nav.focusWorkspacePrefix}+${toString n}" "focus-workspace ${toString n}")
          (bind "${nav.moveToWorkspacePrefix}+${toString n}" "move-column-to-workspace ${toString n}")
        ]) (lib.range 1 9);

        proportions = lib.concatMapStrings (p: "proportion ${p}; ") [
          "0.33333"
          "0.5"
          "0.66667"
          "1.0"
        ];

        configKdl = ''
          prefer-no-csd
          hotkey-overlay { skip-at-startup; }

          input {
            keyboard {
              xkb {
                layout "us,de"
                options "grp:win_space_toggle"
              }
              repeat-delay 600
              repeat-rate 25
              track-layout "global"
            }
            touchpad {
              tap
              dwt
              natural-scroll
              accel-speed 0.0
              accel-profile "adaptive"
            }
            mouse {
              accel-speed 0.0
              accel-profile "adaptive"
            }
          }

          overview { backdrop-color "${colors.base00}"; }

          layout {
            center-focused-column "never"
            gaps 10
            background-color "${colors.base00}"
            default-column-width { proportion 0.5; }
            preset-column-widths { ${proportions}}
            preset-window-heights { ${proportions}}
            focus-ring {
              width 1
              active-gradient from="${colors.base0C}" to="${colors.base0D}" angle=90 relative-to="workspace-view"
              inactive-color "${colors.base03}"
              urgent-gradient from="${colors.base08}" to="${colors.base09}" angle=90 relative-to="workspace-view"
            }
            shadow {
              on
              softness 30
              spread 5
              offset x=0 y=5
              color "#0007"
            }
          }

          window-rule {
            clip-to-geometry true
            geometry-corner-radius 5
          }

          window-rule {
            match app-id="^dev\\.mrbandler\\.scratch-terminal$"
            open-floating true
            open-focused true
            default-column-width { proportion 0.7; }
            default-window-height { proportion 0.6; }
          }

          window-rule {
            match app-id="^zen" title="^Picture-in-Picture$"
            open-floating true
          }

          // noctalia's settings window
          window-rule {
            match app-id="dev.noctalia.Noctalia"
            open-floating true
          }

          binds {
          ${lib.concatMapStrings (b: "  ${b}\n") binds}}

          ${config.desktop.niri.extraConfig}
        '';
      in
      {
        imports = [ ../core/_keybindings.nix ];

        options.desktop.niri.extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Host-specific niri KDL: outputs, workspaces, window rules, spawn-at-startup.";
        };

        config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          xdg.configFile."niri/config.kdl".source =
            pkgs.runCommand "niri-config.kdl"
              {
                nativeBuildInputs = [ pkgs.niri ];
                config = configKdl;
                passAsFile = [ "config" ];
              }
              ''
                niri validate -c "$configPath"
                cp "$configPath" "$out"
              '';
        };
      };
  };
}
