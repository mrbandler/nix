{
  den.aspects.cli.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      profileBins = [
        "${config.home.profileDirectory}/bin"
        "/run/current-system/sw/bin"
        "/nix/var/nix/profiles/default/bin"
      ]
      ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "/opt/homebrew/bin";
    in
    {
      programs.nushell = {
        enable = true;

        settings = {
          show_banner = false;
          history = {
            file_format = "sqlite";
            max_size = 100000;
          };
          completions = {
            case_sensitive = false;
            partial = true;
            quick = true;
            algorithm = "fuzzy";
          };
          shell_integration = {
            osc2 = true;
            osc7 = true;
            osc133 = true;
            osc633 = true;
          };
        };

        # nushell never sources hm-session-vars.sh, so it gets the same variables
        # directly. TERMINFO_DIRS carries POSIX expansion syntax and stays with
        # the POSIX shells.
        environmentVariables = builtins.removeAttrs config.home.sessionVariables [ "TERMINFO_DIRS" ];

        # A terminal launched from the GUI (launchd on macOS) starts without the
        # nix profiles on PATH. The POSIX shells get them from the /etc hooks,
        # nushell has to add them itself.
        extraEnv = ''
          $env.PATH = ($env.PATH | prepend [ ${
            lib.concatMapStringsSep " " (p: "\"${p}\"") profileBins
          } ] | uniq)
        '';
      };
    };
}
