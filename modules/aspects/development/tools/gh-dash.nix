{
  den.aspects.development.homeManager =
    { pkgs, ... }:
    {
      # gh-enhance is the GitHub Actions TUI the dashboard binds to `a`
      home.packages = [ pkgs.gh-enhance ];

      programs.gh-dash = {
        enable = true;
        settings.keybindings.prs = [
          {
            key = "d";
            name = "diffnav";
            command = "gh pr diff --repo {{.RepoName}} {{.PrNumber}} | diffnav";
          }
          {
            key = "a";
            name = "enhance";
            command = "gh-enhance";
          }
        ];
      };
    };
}
