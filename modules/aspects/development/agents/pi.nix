# Pi coding agent; zeus-only for now, as in the old config
{
  den.aspects.development.homeManager =
    { lib, pkgs, ... }:
    {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.pi-coding-agent ];
    };
}
