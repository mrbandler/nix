{
  den.aspects.cli.homeManager =
    { config, lib, ... }:
    {
      programs.eza = {
        enable = true;
        icons = "auto";
        git = true;
        enableBashIntegration = config.programs.bash.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        # zsh takes the aliases below instead: they replace ls, and Claude Code
        # runs its commands in a snapshot of the interactive zsh
        enableZshIntegration = false;
      };

      programs.zsh.initContent = lib.mkIf config.programs.zsh.enable ''
        if [ -z "''${CLAUDECODE:-}" ]; then
          alias -- ls=eza
          alias -- ll='eza -l'
          alias -- la='eza -a'
          alias -- lt='eza --tree'
          alias -- lla='eza -la'
        fi
      '';
    };
}
