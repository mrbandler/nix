{ lib, inputs, ... }:
let
  nixpkgsDefaults = {
    config.allowUnfree = true;
    overlays = [ inputs.nur.overlays.default ];
  };
  # An unmanaged file at a managed path is moved to <file>.bak instead of
  # failing the activation; a stale backup from an earlier takeover is replaced.
  homeManagerBackup = {
    backupFileExtension = "bak";
    overwriteBackup = true;
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
        home-manager = homeManagerBackup;
      };

      nixos = {
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        # hosts installed earlier keep the release they were installed with
        system.stateVersion = lib.mkDefault "26.05";
        nixpkgs = nixpkgsDefaults;
        home-manager = homeManagerBackup;
      };

      homeManager = {
        home.stateVersion = lib.mkDefault "26.05";
        nixpkgs = nixpkgsDefaults;
        # XDG base directories everywhere: exports XDG_* and keeps the modules
        # that would otherwise use ~/Library/Application Support in ~/.config
        xdg.enable = true;
      };
    };

    schema.user.classes = lib.mkDefault [ "homeManager" ];
  };
}
