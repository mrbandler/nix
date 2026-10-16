# macOS's login shell, and the shell Claude Code runs its commands in (from a
# snapshot of the interactive config). Kept as close to nushell as zsh allows;
# the tools hook in from their own modules.
{
  den.aspects.cli.homeManager =
    { config, lib, ... }:
    {
      programs.zsh = {
        enable = true;

        # Claude Code gets a plain zsh, as bash's non-interactive shells do:
        # no aliases, functions or prompt hooks shadowing the standard tools.
        # The environment comes from .zshenv, so nothing it needs is skipped.
        # Ahead of home-manager's own setup, which starts at order 510.
        initContent = lib.mkOrder 100 ''
          [[ -n ''${CLAUDECODE:-} ]] && return
        '';

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
