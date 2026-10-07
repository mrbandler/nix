{
  den.aspects.cli.homeManager =
    { config, ... }:
    {
      programs.carapace = {
        enable = true;
        enableBashIntegration = config.programs.bash.enable;
        enableZshIntegration = config.programs.zsh.enable;
        enableNushellIntegration = config.programs.nushell.enable;
      };
    };
}
