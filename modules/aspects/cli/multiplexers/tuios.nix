# On trial as a zellij/tmux replacement. No home-manager module yet, so the
# config is written directly; tuios fills everything left out with defaults.
{
  den.aspects.cli.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      toml = pkgs.formats.toml { };
    in
    {
      home.packages = [ pkgs.tuios ];

      xdg.configFile."tuios/config.toml".source = toml.generate "tuios-config.toml" {
        appearance = {
          theme = "catppuccin_mocha";
          # the same shell wezterm launches, by store path
          preferred_shell = lib.getExe config.programs.nushell.package;
        };
      };
    };
}
