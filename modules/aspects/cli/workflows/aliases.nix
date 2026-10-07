{
  den.aspects.cli.homeManager =
    { config, lib, ... }:
    let
      # Stand-ins for standard tools. Claude Code runs its commands in a
      # snapshot of the interactive zsh, where `du -sh` or `cat x | ...` must
      # keep meaning the originals, so the POSIX shells skip these there.
      replacements = {
        cat = "bat";
        df = "duf";
        du = "dust";
        top = "btop";
        watch = "viddy";
      };

      shortcuts = {
        # Git
        lg = "lazygit";
        gs = "git status";
        gd = "git diff";
        gl = "git log --oneline";
        gp = "git pull";
        gcm = "git commit -m";
        ga = "git add";

        # Editor
        zed = "zeditor";

        # System
        ff = "fastfetch";

        # Container
        ld = "lazydocker";
        dk = "docker compose";
        dku = "docker compose up -d";
        dkd = "docker compose down";
        kk = "k9s";
      };

      humanOnly = ''
        if [ -z "''${CLAUDECODE:-}" ]; then
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: value: "  alias -- ${name}=${lib.escapeShellArg value}") replacements
        )}
        fi
      '';
    in
    {
      programs.nushell.shellAliases = shortcuts // replacements;

      # home.shellAliases reaches bash and zsh, not nushell
      home.shellAliases = shortcuts;
      programs.zsh.initContent = lib.mkIf config.programs.zsh.enable humanOnly;
      programs.bash.initExtra = lib.mkIf config.programs.bash.enable humanOnly;
    };
}
