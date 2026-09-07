# nx: the Nix management commands. Inputs move through the CI pull requests,
# so "update" means pulling main, never a local `nix flake update`.
{
  den.aspects.cli.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      flakeDir = config.programs.nh.flake;
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      nh = "nh ${if isDarwin then "darwin" else "os"}";
      # nh has no rollback for nix-darwin, darwin-rebuild does
      rollback = if isDarwin then "sudo darwin-rebuild --rollback" else "nh os rollback";

      nushellCommands = ''
        # nx - Nix management commands

        def "nx rebuild" [] { ${nh} switch }
        def "nx rb" [] { nx rebuild }

        def "nx build" [] { ${nh} build }
        def "nx bd" [] { nx build }

        def "nx check" [] { cd ${flakeDir}; nix flake check }
        def "nx ck" [] { nx check }

        def "nx show" [] { cd ${flakeDir}; nix flake show }
        def "nx sw" [] { nx show }

        def "nx update" [] { git -C ${flakeDir} pull --ff-only }
        def "nx up" [] { nx update }

        def "nx upgrade" [] { nx update; nx rebuild }
        def "nx ug" [] { nx upgrade }

        def "nx rollback" [] { ${rollback} }
        def "nx rlb" [] { nx rollback }

        def "nx history" [] { sudo nix-env --list-generations --profile /nix/var/nix/profiles/system }
        def "nx hy" [] { nx history }

        def "nx gc" [] { nh clean user }

        def "nx gc-all" [] { nh clean all }
        def "nx gca" [] { nx gc-all }

        def "nx optimize" [] { nix store optimise }
        def "nx opt" [] { nx optimize }

        def "nx search" [query: string] { nh search $query }
        def "nx sr" [query: string] { nx search $query }

        def "nx repl" [] { cd ${flakeDir}; nix repl . }
        def "nx rp" [] { nx repl }

        # nx top-level shortcuts
        def nxr [] { nx rebuild }
        def nxb [] { nx build }
        def nxc [] { nx check }
        def nxs [] { nx show }
        def nxu [] { nx update }
        def nxg [] { nx upgrade }

      '';

      bashCommands = ''
        # nx - Nix management commands
        nx() {
          local cmd="$1"
          shift 2>/dev/null

          case "$cmd" in
            rebuild|rb)   ${nh} switch ;;
            build|bd)     ${nh} build ;;
            check|ck)     (cd ${flakeDir} && nix flake check) ;;
            show|sw)      (cd ${flakeDir} && nix flake show) ;;
            update|up)    git -C ${flakeDir} pull --ff-only ;;
            upgrade|ug)   nx update && nx rebuild ;;
            rollback|rlb) ${rollback} ;;
            history|hy)   sudo nix-env --list-generations --profile /nix/var/nix/profiles/system ;;
            gc)           nh clean user ;;
            gc-all|gca)   nh clean all ;;
            optimize|opt) nix store optimise ;;
            search|sr)    nh search "$1" ;;
            repl|rp)      (cd ${flakeDir} && nix repl .) ;;
            *)
              echo "nx: unknown command '$cmd'"
              echo "Commands: rebuild(rb) build(bd) check(ck) show(sw) update(up)"
              echo "          upgrade(ug) rollback(rlb) history(hy)"
              echo "          gc gc-all(gca) optimize(opt) search(sr) repl(rp)"
              return 1
              ;;
          esac
        }

        # nx top-level shortcuts
        alias nxr='nx rebuild'
        alias nxb='nx build'
        alias nxc='nx check'
        alias nxs='nx show'
        alias nxu='nx update'
        alias nxg='nx upgrade'
      '';
    in
    {
      programs.nushell.extraConfig = lib.mkIf config.programs.nushell.enable nushellCommands;
      programs.bash.initExtra = lib.mkIf config.programs.bash.enable bashCommands;
    };
}
