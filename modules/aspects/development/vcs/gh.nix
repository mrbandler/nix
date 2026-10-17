{
  den.aspects.development.provides.vcs.homeManager =
    { config, lib, ... }:
    let
      tokenFile = config.programs.onepassword-secrets.secretPaths.githubToken;
    in
    {
      programs.gh = {
        enable = true;
        settings.git_protocol = "ssh";
      };

      # log gh in from the opnix token so every gh binary (e.g. a project's
      # devenv one) finds it in gh's own credential store
      home.activation.ghAuth = lib.hm.dag.entryAfter [ "retrieveOpnixSecrets" ] ''
        if [ -r ${tokenFile} ]; then
          ${lib.getExe config.programs.gh.package} auth login --hostname github.com --with-token < ${tokenFile} \
            || echo "gh: login from the opnix token failed, run 'gh auth login' manually" >&2
        fi
      '';
    };
}
