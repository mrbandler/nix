{
  den.aspects.cli.homeManager =
    { pkgs, ... }:
    let
      jsonFormat = pkgs.formats.json { };
    in
    {
      home.packages = [ pkgs.xh ];

      xdg.configFile."xh/config.json".source = jsonFormat.generate "xh-config.json" {
        default_options = [
          "--style=auto"
          "--pretty=all"
        ];
      };
    };
}
