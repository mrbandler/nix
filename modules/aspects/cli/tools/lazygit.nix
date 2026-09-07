{
  den.aspects.cli.homeManager =
    { config, lib, ... }:
    {
      programs.lazygit = {
        enable = true;
        settings = {
          gui.nerdFontsVersion = "3";
        }
        // lib.optionalAttrs config.programs.delta.enable {
          git.diffRenderers = [
            {
              type = "stdinFilter";
              name = "delta";
              colorArg = "always";
              command = "delta --paging=never";
            }
          ];
        };
      };
    };
}
