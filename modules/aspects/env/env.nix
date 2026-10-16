# Session variables ride with the shell, so they feed the cli aspect.
{
  den.aspects.cli.homeManager =
    { pkgs, ... }:
    {
      home.sessionVariables = {
        TERMINAL = if pkgs.stdenv.hostPlatform.isLinux then "ghostty" else "wezterm";
        EDITOR = "hx";
        VISUAL = "zeditor";
        PAGER = "bat --style=plain";
        BROWSER = "zen-beta";
      };
    };
}
