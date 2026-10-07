{
  den.aspects.development.provides.vcs.homeManager =
    { config, pkgs, ... }:
    let
      tokenFile = config.programs.onepassword-secrets.secretPaths.githubToken;

      # scope the token to gh's own process rather than exporting GH_TOKEN
      # into every shell, where any tool (or agent) could read it
      gh = pkgs.symlinkJoin {
        name = "gh-${pkgs.gh.version}";
        paths = [ pkgs.gh ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/gh \
            --run 'if [ -z "''${GH_TOKEN:-}" ] && [ -r ${tokenFile} ]; then export GH_TOKEN="$(< ${tokenFile})"; fi'
        '';
        inherit (pkgs.gh) meta;
      };
    in
    {
      programs.gh = {
        enable = true;
        package = gh;
        settings.git_protocol = "ssh";
      };
    };
}
