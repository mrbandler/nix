{
  den.aspects.development.homeManager =
    { pkgs, ... }:
    let
      yamlFormat = pkgs.formats.yaml { };
    in
    {
      home.packages = [ pkgs.diffnav ];

      xdg.configFile."diffnav/config.yml".source = yamlFormat.generate "diffnav-config.yml" {
        ui = {
          showFileTree = true;
          sideBySide = true;
          icons = "nerd-fonts-full";
          colorFileNames = true;
          showDiffStats = true;
        };
      };
    };
}
