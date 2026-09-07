{
  den.aspects.apps.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      yamlFormat = pkgs.formats.yaml { };
      configDir = "${config.xdg.configHome}/jrnl";
      configFile = yamlFormat.generate "jrnl.yaml" {
        default_hour = 9;
        default_minute = 0;
        editor = "hx";
        encrypt = false;
        highlight = true;
        indent = 2;
        linewrap = 120;
        tagsymbols = "@";
        template = false;
        timeformat = "%F %H:%M";
        journals.default.journal = "~/.local/share/jrnl/journal.txt";
      };
    in
    {
      programs.jrnl.enable = true;

      # jrnl rewrites its config at runtime, so it gets a mutable copy rather
      # than the store symlink programs.jrnl.settings would place there
      home.activation.jrnlConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${lib.escapeShellArg configDir}
        run install -m644 ${configFile} ${lib.escapeShellArg "${configDir}/jrnl.yaml"}
      '';
    };
}
