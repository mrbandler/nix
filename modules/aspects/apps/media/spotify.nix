{
  den.aspects.apps.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.spotifast ];
    };
}
