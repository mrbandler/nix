{
  den.aspects.cli.homeManager =
    { config, lib, ... }:
    {
      programs.fzf = {
        enable = true;
        enableBashIntegration = config.programs.bash.enable;
        defaultCommand = lib.mkIf config.programs.fd.enable "fd --type f";
        # Ctrl-R belongs to atuin
        historyWidget.command = "";
      };
    };
}
