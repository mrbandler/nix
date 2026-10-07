{
  den.aspects.development.homeManager =
    { pkgs, ... }:
    let
      # nixpkgs ships graphify as an application, whose bin/graphify is a bash
      # wrapper; the skill's interpreter probe can't read a python from that
      # shebang and falls back to pip-installing graphifyy into the system
      # python. Hand it an interpreter that already imports graphify instead.
      python = pkgs.python3.withPackages (_: [ (pkgs.python3.pkgs.toPythonModule pkgs.graphify) ]);
      site = "${pkgs.graphify}/${pkgs.python3.sitePackages}/graphify";

      # mirrors what `graphify install` copies for claude: the lean SKILL.md
      # plus the references/ it links to
      skill = pkgs.runCommandLocal "graphify-claude-skill" { } ''
        mkdir -p $out
        cp ${site}/skill.md $out/SKILL.md
        cp -r ${site}/skills/claude/references $out/references
        substituteInPlace $out/SKILL.md \
          --replace-fail 'PYTHON=""' 'PYTHON="${python}/bin/python3"'
      '';
    in
    {
      home.packages = [ pkgs.graphify ];

      programs.claude-code.skills.graphify = skill;
    };
}
