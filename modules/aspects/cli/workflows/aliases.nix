{
  den.aspects.cli.homeManager =
    let
      # Stand-ins for standard tools
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

    in
    {
      programs.nushell.shellAliases = shortcuts // replacements;

      # home.shellAliases reaches bash and zsh, not nushell
      home.shellAliases = shortcuts // replacements;
    };
}
