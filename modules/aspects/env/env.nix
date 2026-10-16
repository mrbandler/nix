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

      # user-installed CLIs (e.g. the claude-mem launcher) land here, and their
      # installers can't edit the nix-managed rc files to add it themselves
      home.sessionPath = [ "$HOME/.local/bin" ];
    };
}
