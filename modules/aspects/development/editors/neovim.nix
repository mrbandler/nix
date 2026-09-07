{
  den.aspects.development.homeManager =
    { pkgs, ... }:
    {
      programs.neovim = {
        enable = true;
        defaultEditor = false;
        vimAlias = true;
        viAlias = true;

        # treesitter parsers compile at runtime
        extraPackages = with pkgs; [
          gcc
          gnumake
        ];
      };

      # LazyVim owns the config directory and brings its own catppuccin; the
      # stylix target would generate an init.lua into the same place.
      stylix.targets.neovim.enable = false;
      xdg.configFile."nvim".source = ./_neovim;
    };
}
