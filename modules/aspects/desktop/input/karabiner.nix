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

        # "Mod2+S" -> { key_code = "s"; modifiers.mandatory = [ "fn" "control" ]; }
        mods = {
          Mod = [ "fn" ];
          Mod2 = [
            "fn"
            "control"
          ];
        };
        keyCodes = {
          return = "return_or_enter";
          space = "spacebar";
        };
        from =
          bindStr:
          let
            parts = lib.splitString "+" bindStr;
            key = lib.toLower (lib.last parts);
          in
          {
            key_code = keyCodes.${key} or key;
            modifiers.mandatory = lib.concatMap (m: mods.${m}) (lib.init parts);
          };
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
                        to_if_alone = [
                          { shell_command = "${config.home.homeDirectory}/.nix-profile/bin/vicinae toggle"; }
                        ];
                      }
                    ];
                  }
                  {
                    # 1Password has no launch command for Quick Access; its own
                    # shortcut (shift+cmd+space by default) is sent instead
                    description = "Password manager key opens 1Password Quick Access";
                    manipulators = [
                      {
                        type = "basic";
                        from = from kb.applications.passwordManager;
                        to = [
                          {
                            key_code = "spacebar";
                            modifiers = [
                              "left_shift"
                              "left_command"
                            ];
                          }
                        ];
                      }
                    ];
                  }
                ];
              }
            ];
          };
        };
      };
  };
}
