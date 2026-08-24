{
  den.aspects.apps = {
    homeManager =
      { lib, ... }:
      {
        programs.obsidian.enable = lib.mkDefault true;
      };
  };
}
