{
  den.aspects.cli.homeManager =
    { config, pkgs, ... }:
    let
      yamlFormat = pkgs.formats.yaml { };
      # glow reads its platform config dir (go-app-paths), which on macOS is
      # ~/Library/Preferences rather than ~/.config
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Preferences/glow"
        else
          "${config.xdg.configHome}/glow";
    in
    {
      home.packages = [ pkgs.glow ];

      home.file."${configDir}/glow.yml".source = yamlFormat.generate "glow.yml" {
        style = "auto";
        width = 0;
        pager = true;
        mouse = true;
        showLineNumbers = true;
      };
    };
}
