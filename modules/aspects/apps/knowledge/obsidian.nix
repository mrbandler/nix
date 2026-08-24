{
  den.aspects.apps = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        vaultsDir = "${config.home.homeDirectory}/.vaults";
        vaultRepos = {
          "second-brain" = "git@github.com:mrbandler/second-brain.git";
          "dnd" = "git@github.com:mrbandler/dnd.git";
        };
      in
      {
        programs.obsidian = {
          enable = true;
          package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin null;
          vaults = lib.mapAttrs (name: _: { target = ".vaults/${name}"; }) vaultRepos;
        };

        home.activation.cloneObsidianVaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          export GIT_SSH_COMMAND="${lib.getExe' pkgs.openssh "ssh"} -o StrictHostKeyChecking=accept-new"
          ${lib.concatLines (
            lib.mapAttrsToList (name: url: ''
              if [ ! -e ${lib.escapeShellArg "${vaultsDir}/${name}"}/.git ]; then
                run ${lib.getExe pkgs.git} clone ${url} ${lib.escapeShellArg "${vaultsDir}/${name}"} \
                  || warnEcho "cloneObsidianVaults: cloning ${url} failed"
              fi
            '') vaultRepos
          )}
        '';
      };

    provides.to-hosts.darwin.homebrew.casks = [ "obsidian" ];
  };
}
