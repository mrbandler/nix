{
  den.aspects.cli.homeManager.programs.nushell.shellAliases = {
    # Modern replacements
    cat = "bat";
    df = "duf";
    du = "dust";

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
    top = "btop";
    watch = "viddy";

    # Container
    ld = "lazydocker";
    dk = "docker compose";
    dku = "docker compose up -d";
    dkd = "docker compose down";
    kk = "k9s";
  };
}
