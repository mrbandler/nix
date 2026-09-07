{
  den.aspects.cli.homeManager =
    { config, ... }:
    {
      programs.yazi = {
        enable = true;
        enableBashIntegration = config.programs.bash.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        shellWrapperName = "y";
      };
    };
}
