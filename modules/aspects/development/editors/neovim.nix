{
  den.aspects.development.homeManager =
    { pkgs, ... }:
    {
      programs.neovim = {
        enable = true;
        defaultEditor = false;
        vimAlias = true;
        viAlias = true;
        # the 26.05 defaults, also on hosts installed earlier
        withRuby = false;
        withPython3 = false;

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
