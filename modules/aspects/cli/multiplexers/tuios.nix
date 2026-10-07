# On trial as a zellij/tmux replacement; no home-manager module yet, so it
# runs on its defaults.
{
  den.aspects.cli.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.tuios ];
    };
}
