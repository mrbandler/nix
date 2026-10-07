{
  den.aspects.development.homeManager =
    { pkgs, ... }:
    {
      # the plugin's hooks shell out to bun for its worker and to uv for the
      # chroma vector search; only the npx installer bootstraps them, the
      # plugin path just errors out when they're missing
      home.packages = [
        pkgs.bun
        pkgs.uv
      ];

      programs.claude-code.settings = {
        extraKnownMarketplaces.thedotmack.source = {
          source = "github";
          repo = "thedotmack/claude-mem";
        };

        enabledPlugins."claude-mem@thedotmack" = true;
      };
    };
}
