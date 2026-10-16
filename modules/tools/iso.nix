# `nix build .#iso` (on x86_64-linux): the NixOS installer with flakes on and
# the install tool built in, so installing is `install <host>` on the stick.
# Root accepts the 1Password SSH key, so `install <host> <address>` from
# another machine needs no password on the stick either.
{ inputs, lib, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      identity = import ../aspects/development/vcs/_identity.nix {
        devDir = "";
        inherit pkgs;
      };
      iso = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          {
            nixpkgs.hostPlatform = system;
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
            environment.systemPackages = [ config.packages.install ];
            users.users.root.openssh.authorizedKeys.keys = [ identity.signing.key ];
          }
        ];
      };
    in
    {
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        iso = iso.config.system.build.isoImage;
      };
    };
}
