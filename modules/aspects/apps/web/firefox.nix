{
  den.aspects.apps.homeManager =
    { config, ... }:
    {
      stylix.targets.firefox.profileNames = [ config.home.username ];

      programs.firefox.enable = true;
    };
}
