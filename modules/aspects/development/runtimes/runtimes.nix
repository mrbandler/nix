{
  den.aspects.development.homeManager =
    { pkgs, ... }:
    let
      nodejs = pkgs.nodejs_22;
    in
    {
      home.packages = [
        nodejs
        pkgs.python3
      ];

      home.sessionVariables.NODE_PATH = "${nodejs}/lib/node_modules";
    };
}
