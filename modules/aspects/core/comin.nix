{ inputs, ... }:
{
  flake-file.inputs.comin = {
    url = "github:nlewo/comin";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.core.provides.comin =
    let
      comin = {
        enable = true;
        remotes = [
          {
            name = "origin";
            url = "https://github.com/mrbandler/nix.git";
            branches.main.name = "main";
          }
        ];
      };
    in
    {
      darwin = {
        imports = [ inputs.comin.darwinModules.comin ];
        services.comin = comin;
      };
      nixos = {
        imports = [ inputs.comin.nixosModules.comin ];
        services.comin = comin;
      };
    };
}
