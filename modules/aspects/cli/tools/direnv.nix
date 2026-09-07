{
  den.aspects.cli.homeManager =
    { config, ... }:
    {
      imports = [ ../../development/core/_devdir.nix ];

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        config = {
          hide_env_diff = true;
          load_dotenv = true;
          warn_timeout = "10s";
          whitelist.prefix = [ config.development.devDir ];
        };
      };
    };
}
