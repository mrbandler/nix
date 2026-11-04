{
  den.aspects.development.homeManager =
    { pkgs, ... }:
    let
      py = pkgs.python3Packages;

      # The PyPI name `agent-reach` belongs to another project, so build from
      # the GitHub tag.
      agent-reach = py.buildPythonApplication rec {
        pname = "agent-reach";
        version = "1.6.1";
        pyproject = true;

        src = pkgs.fetchFromGitHub {
          owner = "Panniantong";
          repo = "Agent-Reach";
          tag = "v${version}";
          hash = "sha256-l2mRKME24eoLwUUQPuEl0y6gEIGVNuEJc9pz23hX8Z0=";
        };

        build-system = [ py.hatchling ];
        dependencies = with py; [
          requests
          loguru
          pyyaml
          yt-dlp
        ];

        # The youtube channel runs `python -m yt_dlp` in a subprocess. That
        # subprocess does not get the wrapper's sys.path, so give it yt-dlp on
        # PYTHONPATH, and deno for YouTube's JS challenges. The github channel
        # runs `gh api`.
        makeWrapperArgs = [
          "--prefix PYTHONPATH : ${py.makePythonPath [ py.yt-dlp ]}"
          "--prefix PATH : ${
            pkgs.lib.makeBinPath [
              pkgs.deno
              pkgs.gh
            ]
          }"
        ];

        pythonImportsCheck = [ "agent_reach" ];
      };

      # Render the skill with the upstream renderer, as `agent-reach install`
      # does, so the channel table and version match the package.
      skill =
        pkgs.runCommandLocal "agent-reach-claude-skill" { }
          ''
            mkdir -p $out
            ${pkgs.python3.withPackages (_: [ (py.toPythonModule agent-reach) ])}/bin/python3 -c \
              'from agent_reach.runtime.manage import render_skill; print(render_skill("en"), end="")' \
              > $out/SKILL.md
            cp -r ${agent-reach}/${pkgs.python3.sitePackages}/agent_reach/skill/references $out/references
          '';
    in
    {
      home.packages = [ agent-reach ];

      programs.claude-code.skills.agent-reach = skill;
    };
}
