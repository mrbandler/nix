{
  den.aspects.cli.homeManager =
    { pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
    in
    {
      home.packages = [ pkgs.tailspin ];

      xdg.configFile."tailspin/theme.toml".source = tomlFormat.generate "tailspin-theme.toml" {
        numbers.style.fg = "cyan";
        dates = {
          date.fg = "magenta";
          time.fg = "blue";
          zone.fg = "red";
        };
        urls = {
          http.fg = "red";
          https.fg = "green";
          host.fg = "blue";
          path.fg = "blue";
          query_params_key.fg = "magenta";
          query_params_value.fg = "cyan";
          symbols.fg = "red";
        };
        json.key.fg = "yellow";
      };
    };
}
