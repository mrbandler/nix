{ lib, inputs, ... }:
let
  nixpkgsDefaults = {
    config.allowUnfree = true;
    overlays = [ inputs.nur.overlays.default ];
  };
in
{
  den = {
    default = {
      darwin = {
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        system.stateVersion = 6;
        nixpkgs = nixpkgsDefaults;
      };

      nixos = {
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        system.stateVersion = "26.05";
        nixpkgs = nixpkgsDefaults;
      };

      homeManager = {
        home.stateVersion = "26.05";
        nixpkgs = nixpkgsDefaults;
      };
    };

    schema.user.classes = lib.mkDefault [ "homeManager" ];
  };
}
