{
  den.aspects.cli.homeManager =
    { config, ... }:
    {
      programs.eza = {
        enable = true;
        icons = "auto";
        git = true;
        enableBashIntegration = config.programs.bash.enable;
        enableNushellIntegration = config.programs.nushell.enable;
      };
    };
}
