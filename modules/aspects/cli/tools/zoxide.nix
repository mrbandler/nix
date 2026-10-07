{
  den.aspects.cli.homeManager =
    { config, ... }:
    {
      programs.zoxide = {
        enable = true;
        enableBashIntegration = config.programs.bash.enable;
        enableZshIntegration = config.programs.zsh.enable;
        enableNushellIntegration = config.programs.nushell.enable;
      };
    };
}
