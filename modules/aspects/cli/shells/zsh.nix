# macOS's login shell, and the shell Claude Code runs its commands in (from a
# snapshot of the interactive config). Kept as close to nushell as zsh allows;
# the tools hook in from their own modules.
{
  den.aspects.cli.homeManager =
    { config, ... }:
    {
      programs.zsh = {
        enable = true;

        # nushell's inline hints and highlighting
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        history = {
          size = 100000;
          save = 100000;
          path = "${config.xdg.stateHome}/zsh/history";
          ignoreDups = true;
          ignoreSpace = true;
          share = true;
        };
      };
    };
}
