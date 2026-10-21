{
  den.aspects.desktop.provides.karabiner = {
    provides.to-hosts.darwin.homebrew.casks = [ "karabiner-elements" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        kb = config.desktop.keybindings;
        vicinae = "${config.home.homeDirectory}/.nix-profile/bin/vicinae toggle";

        # Super and Super+Alt as on Linux, by position: left option is the
        # Super spot on the MacBook and cmd the Alt spot. An external keyboard's
        # Super key reaches macOS as cmd and its Alt as option, so those two are
        # swapped first to match the MacBook. Only the chords in the keybinding
        # map are rewritten; everything else passes through.
        superMods = {
          Mod = [ "left_option" ];
          Mod2 = [
            "left_option"
            "left_command"
          ];
        };
        builtIn = [
          {
            type = "device_if";
            identifiers = [ { is_built_in_keyboard = true; } ];
          }
        ];
        external = [
          {
            type = "device_unless";
            identifiers = [ { is_built_in_keyboard = true; } ];
          }
        ];
        # what the window manager binds instead: chords no app uses
        # (aerospace.nix binds the same)
        wmMods = {
          Mod = [
            "left_control"
            "left_option"
            "left_shift"
          ];
          Mod2 = [
            "left_control"
            "left_option"
            "left_shift"
            "left_command"
          ];
        };
        keyCodes = {
          return = "return_or_enter";
          space = "spacebar";
          minus = "hyphen";
          equal = "equal_sign";
          bracketleft = "open_bracket";
          bracketright = "close_bracket";
        };

        # "Mod2+H" -> { mod = "Mod2"; key = "h"; }
        parse =
          bindStr:
          let
            parts = lib.splitString "+" bindStr;
            key = lib.toLower (lib.last parts);
          in
          {
            mod = lib.head parts;
            key = keyCodes.${key} or key;
          };
        remap =
          bindStr: to:
          let
            bind = parse bindStr;
          in
          {
            type = "basic";
            from = {
              key_code = bind.key;
              modifiers.mandatory = superMods.${bind.mod};
            };
            to = to bind;
          };

        # every bind in the map, the numbered workspace binds spelled out
        prefixes = with kb.navigation; [
          focusWorkspacePrefix
          moveToWorkspacePrefix
        ];
        binds =
          lib.flatten (
            lib.collect (v: !lib.isAttrs v) (
              kb
              // {
                navigation = removeAttrs kb.navigation [
                  "focusWorkspacePrefix"
                  "moveToWorkspacePrefix"
                ];
              }
            )
          )
          ++ lib.concatMap (p: map (n: "${p}+${toString n}") (lib.range 1 9)) prefixes;
      in
      {
        imports = [ ../core/_keybindings.nix ];

        config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          xdg.configFile."karabiner/karabiner.json".text = builtins.toJSON {
            profiles = [
              {
                name = "Default";
                selected = true;
                virtual_hid_keyboard.keyboard_type_v2 = "ansi";
                complex_modifications.rules = [
                  {
                    description = "Fn alone toggles vicinae";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "fn";
                          modifiers.optional = [ "any" ];
                        };
                        to = [
                          {
                            key_code = "fn";
                            lazy = true;
                          }
                        ];
                        to_if_alone = [ { shell_command = vicinae; } ];
                      }
                    ];
                  }
                  {
                    # keyd does the same with Super on Linux; on an external
                    # keyboard this is also the Super to option half of the swap
                    description = "Super alone toggles vicinae";
                    manipulators =
                      map
                        (
                          { from, conditions }:
                          {
                            type = "basic";
                            from = {
                              key_code = from;
                              modifiers.optional = [ "any" ];
                            };
                            to = [
                              {
                                key_code = "left_option";
                                lazy = true;
                              }
                            ];
                            to_if_alone = [ { shell_command = vicinae; } ];
                            inherit conditions;
                          }
                        )
                        [
                          {
                            from = "left_option";
                            conditions = builtIn;
                          }
                          {
                            from = "left_command";
                            conditions = external;
                          }
                        ];
                  }
                  {
                    description = "External keyboards: Alt acts as cmd, as on the MacBook";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "left_option";
                          modifiers.optional = [ "any" ];
                        };
                        to = [ { key_code = "left_command"; } ];
                        conditions = external;
                      }
                    ];
                  }
                  {
                    # 1Password has no launch command for Quick Access; its own
                    # shortcut (shift+cmd+space by default) is sent instead
                    description = "Password manager key opens 1Password Quick Access";
                    manipulators = [
                      (remap kb.applications.passwordManager (_: [
                        {
                          key_code = "spacebar";
                          modifiers = [
                            "left_shift"
                            "left_command"
                          ];
                        }
                      ]))
                    ];
                  }
                  {
                    description = "Super chords go to the window manager";
                    manipulators = map (
                      bindStr:
                      remap bindStr (bind: [
                        {
                          key_code = bind.key;
                          modifiers = wmMods.${bind.mod};
                        }
                      ])
                    ) (lib.remove kb.applications.passwordManager binds);
                  }
                ];
              }
            ];
          };
        };
      };
  };
}
