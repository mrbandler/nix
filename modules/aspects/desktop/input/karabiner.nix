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
      lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
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
              ];
            }
          ];
        };
      };
  };
}
