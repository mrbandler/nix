{
  den.aspects.development.provides.vcs.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      vcs = import ./_identity.nix {
        inherit pkgs;
        devDir = config.development.devDir;
      };
    in
    {
      imports = [ ../core/_devdir.nix ];

      # the delta pager and diff formatter come from programs.delta
      programs.jujutsu = {
        enable = true;
        settings = {
          user = vcs.default;

          signing = {
            backend = "ssh";
            inherit (vcs.signing) key;
            backends.ssh.program = vcs.signing.program;
            behavior = "own"; # sign every own commit, like git's signByDefault
          };

          "--scope" = lib.mapAttrsToList (path: user: {
            "--when".repositories = [ path ];
            inherit user;
          }) vcs.contexts;
        };
      };
    };
}
