{
  den.aspects.apps.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      colors = config.lib.stylix.colors;

      # nb takes xterm-256 color indices; map the stylix hex colors onto the
      # 6x6x6 cube (index 16 onwards, each channel scaled to 0..5).
      hexToInt =
        hex:
        let
          digits = {
            "0" = 0;
            "1" = 1;
            "2" = 2;
            "3" = 3;
            "4" = 4;
            "5" = 5;
            "6" = 6;
            "7" = 7;
            "8" = 8;
            "9" = 9;
            "a" = 10;
            "b" = 11;
            "c" = 12;
            "d" = 13;
            "e" = 14;
            "f" = 15;
          };
        in
        lib.foldl' (acc: c: acc * 16 + digits.${lib.toLower c}) 0 (lib.stringToCharacters hex);

      channelTo6 =
        v:
        if v < 48 then
          0
        else if v < 115 then
          1
        else
          (v - 35) / 40;

      hexTo256 =
        hex:
        let
          r = hexToInt (lib.substring 0 2 hex);
          g = hexToInt (lib.substring 2 2 hex);
          b = hexToInt (lib.substring 4 2 hex);
        in
        16 + (channelTo6 r) * 36 + (channelTo6 g) * 6 + (channelTo6 b);
    in
    {
      home.packages = [ pkgs.nb ];

      home.sessionVariables = {
        NB_EDITOR = "hx";
        NB_DEFAULT_EXTENSION = "md";
        NB_AUTO_SYNC = "1";
        NB_HEADER = "2";
        NB_LIMIT = "20";
        NB_COLOR_PRIMARY = toString (hexTo256 colors.base0D);
        NB_COLOR_SECONDARY = toString (hexTo256 colors.base04);
      };
    };
}
