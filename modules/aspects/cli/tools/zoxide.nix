{
  den.aspects.cli.homeManager =
    { config, ... }:
    {
      programs.zoxide = {
        enable = true;
        enableBashIntegration = config.programs.bash.enable;
        enableNushellIntegration = config.programs.nushell.enable;
      };
    };
}
