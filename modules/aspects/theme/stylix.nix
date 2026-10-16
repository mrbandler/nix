{ inputs, ... }:
{
  flake-file.inputs.stylix = {
    url = "github:danth/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.theme.homeManager =
    { lib, pkgs, ... }:
    {
      imports = [ inputs.stylix.homeModules.stylix ];

      stylix = {
        enable = true;

        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
        polarity = "dark";
        # Artemis II: crescent Earth over the lunar far side, NASA art002e015231
        image = ./_wallpapers/artemis-ii-crescent-earth.jpg;

        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font";
          };

          sizes = {
            applications = 12;
            terminal = 12;
            desktop = 10;
            popups = 10;
          };
        };

        opacity.terminal = 0.95;

        targets = {
          # unused, and its target still sets the renamed programs.rofi.font
          rofi.enable = false;
          # an overlay: rebuilds gtksourceview and all its dependents (inkscape)
          # from source on every bump, for an editor syntax theme
          gtksourceview.enable = false;
        };

        # macOS keeps its own cursor
        cursor = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 24;
        };
      };
    };
}
